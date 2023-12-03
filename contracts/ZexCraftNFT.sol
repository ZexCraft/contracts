// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFV2WrapperConsumerBase.sol";
// import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
// import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


import "./interfaces/IRelationshipRegistry.sol";
import "./interfaces/IERC6551Registry.sol";
import "./interfaces/IRelationship.sol";


contract ZexCraftNFT is ERC721, ERC721URIStorage, VRFV2WrapperConsumerBase, FunctionsClient, ConfirmedOwner {
  using Strings for uint256;
  using FunctionsRequest for FunctionsRequest.Request;

  enum Status {
    DOES_NOT_EXIST,
    VRF_REQUESTED,
    NFT_REQUESTED,
    FUNCTIONS_REQUESTED,
    MINTED
  }

 

  struct RequestStatus {
    uint256 paid; // amount paid in link
    bool fulfilled; // whether the request has been successfully fulfilled
    uint256 randomWord;
  }

  struct ZexCraftNftRequest {
    IRelationship.NFT nft1;
    IRelationship.NFT nft2;
    string prompt;
    uint256 requestId;
    uint256 tokenId;
    uint256 randomness;
    address owner;
    address account;
    Status status;
  }

  // Chainlink Functions Variables
  bytes32 public donId; // DON ID for the Functions DON to which the requests are sent

  bytes32 public s_lastRequestId;
  bytes public s_lastResponse;
  bytes public s_lastError;
  uint32 public s_callbackGasLimit;
  string public sourceCode;
  uint256 public tokenIdCounter;
  mapping(uint256=>uint256) public tokenIdToZexCraftNftRequest;

  // ZexCraftNFT Variables
  IRelationshipRegistry public relRegisty;
  uint256 public mintFee;
  address public linkAddress;
  address public wrapperAddress;
  IERC6551Registry public registry;
  address public erc6551Implementation;
  mapping(address=>bool) public accounts;
  mapping(uint256 => ZexCraftNftRequest) public zexCraftNftRequests;
  mapping(bytes32 => uint256) public functionToVRFRequest;

  // Chainlink VRF Variables
  mapping(uint256 => RequestStatus) public s_requests;

  // past requests Id.
  uint256[] public requestIds;
  uint256 public lastRequestId;

  uint32 v_callbackGasLimit = 100000;
  uint16 public constant requestConfirmations = 3;
  uint32 public constant numWords = 1;


  // // Chainlink CCIP Variables
  address public crossChainAddress;
  // bytes32 public s_lastReceivedMessageId ;
  // bytes public  s_lastReceivedData ;
  // mapping(uint64 => mapping(address => bool)) public allowlistedAddresses;


  constructor(
    address _linkAddress,
    address _wrapperAddress,
    address router,
    bytes32 _donId,
    IRelationshipRegistry _relRegisty,
    string memory _sourceCode,
    uint32 _callbackGasLimit,
    uint256 _mintFee,
    address _crossChainAddress,
    address _implementation,
    IERC6551Registry _registry
    // address _ccipRouter
  )
    ERC721("ZexCraft", "ZCT")
    FunctionsClient(router)
    VRFV2WrapperConsumerBase(_linkAddress, _wrapperAddress)
    ConfirmedOwner(msg.sender)
  {
    donId = _donId;
    relRegisty = _relRegisty;
    sourceCode = _sourceCode;
    s_callbackGasLimit = _callbackGasLimit;
    mintFee = _mintFee;
    linkAddress = _linkAddress;
    wrapperAddress = _wrapperAddress;
    crossChainAddress = _crossChainAddress;
    tokenIdCounter = 1;
    erc6551Implementation = _implementation;
    registry = _registry;
  }

  event OracleReturned(bytes32 requestId, bytes response, bytes error);
  event RequestSent(uint256 requestId, uint32 numWords);
  event RequestFulfilled(uint256 requestId, uint256[] randomWords, uint256 payment);
  event ZexCraftNFTCreated(uint256 tokenId, string tokenUri, address owner);
  event ZexCraftAccountDeployed(address tokenAddress, uint256 tokenId, address account);

    
  modifier onlyRelationship() {
    require(relRegisty.isRelationship(msg.sender), "only relationship");
    _;
  }

  modifier onlyCrosschain() {
    require(msg.sender==crossChainAddress, "only crosschain");
    _;
  }

  function createNewZexCraftNft(string memory prompt) external payable returns (uint256 requestId) {
    require(msg.value>=mintFee,"not enough fee");
    return _createNewZexCraftNft(msg.sender,prompt);
  }

  function createNewZexCraftNftCrossChain(address owner,string memory prompt) external payable onlyCrosschain returns (uint256 requestId) {
    return _createNewZexCraftNft(owner,prompt);
  }


  function _createNewZexCraftNft(address owner,string memory prompt) internal returns (uint256 requestId) {
    requestId = requestRandomness(v_callbackGasLimit, requestConfirmations, numWords);
    s_requests[requestId] = RequestStatus({
      paid: VRF_V2_WRAPPER.calculateRequestPrice(v_callbackGasLimit),
      randomWord: 0,
      fulfilled: false
    });
    requestIds.push(requestId);
    lastRequestId = requestId;
    emit RequestSent(requestId, numWords);
    zexCraftNftRequests[requestId] = ZexCraftNftRequest({
      prompt: prompt,
      nft1: IRelationship.NFT({
        tokenId: 0,
        tokenURI: "",
        ownerDuringMint: address(0),
        contractAddress: address(0),
        chainId: 0,
        sourceChainSelector:0
      }),
      nft2: IRelationship.NFT({
        tokenId: 0,
        tokenURI: "",
        ownerDuringMint: address(0),
        contractAddress: address(0),
        chainId: 0,
        sourceChainSelector:0
      }),
      requestId: requestId,
      randomness: 0,
      tokenId: 0,
      owner:owner,
      account:address(0),
      status: Status.VRF_REQUESTED
    });
    return requestId;
  }

  function createBabyZexCraftNft(
    IRelationship.NFT memory nft1,
    IRelationship.NFT memory nft2
  ) external payable returns (uint256 requestId) {
    require(msg.value>=mintFee,"not enough fee");
    return _createBabyZexCraftNft(nft1, nft2);
  }

  function createBabyZexCraftNftCrosschain(IRelationship.NFT memory nft1,IRelationship.NFT memory nft2) external onlyRelationship returns (uint256 requestId) {
    return _createBabyZexCraftNft(nft1, nft2);
  }

  function _createBabyZexCraftNft(
    IRelationship.NFT memory nft1,
    IRelationship.NFT memory nft2
  ) internal returns (uint256 requestId) {
    requestId = requestRandomness(v_callbackGasLimit, requestConfirmations, numWords);
    s_requests[requestId] = RequestStatus({
      paid: VRF_V2_WRAPPER.calculateRequestPrice(v_callbackGasLimit),
      randomWord: 0,
      fulfilled: false
    });
    requestIds.push(requestId);
    lastRequestId = requestId;
    emit RequestSent(requestId, numWords);
    zexCraftNftRequests[requestId] = ZexCraftNftRequest({
    nft1: nft1,
    nft2: nft2,
    prompt: "",
    tokenId:0,
    requestId: requestId,
     randomness:0,
      account:address(0),
    owner:msg.sender,
      status: Status.VRF_REQUESTED
    });
    return requestId;
  }

  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
    require(s_requests[_requestId].paid > 0, "request not found");
    uint randomWord = _randomWords[0];
    s_requests[_requestId].fulfilled = true;
    s_requests[_requestId].randomWord = randomWord;

    if (zexCraftNftRequests[_requestId].status == Status.VRF_REQUESTED) {
     
      zexCraftNftRequests[_requestId].randomness = randomWord % 100;
      zexCraftNftRequests[_requestId].status = Status.NFT_REQUESTED;
      emit RequestFulfilled(_requestId, _randomWords, s_requests[_requestId].paid);
    } else{
      zexCraftNftRequests[_requestId].randomness = randomWord % 100;
      zexCraftNftRequests[_requestId].status = Status.NFT_REQUESTED;
      emit RequestFulfilled(_requestId, _randomWords, s_requests[_requestId].paid);
    }
  }

  function mintNewZexCraftNft(
    uint256 _requestId,
    string memory seed,
   bytes memory encryptedSecretsUrls,
    uint8 donHostedSecretsSlotID,
    uint64 donHostedSecretsVersion,
    string[] memory args,
    uint64 subscriptionId
  ) public {
    require(zexCraftNftRequests[_requestId].status == Status.NFT_REQUESTED, "request not found");
    require(msg.sender == zexCraftNftRequests[_requestId].owner, "not owner");
    zexCraftNftRequests[_requestId].tokenId=tokenIdCounter;

    args[0] = "NEW_BORN";
    args[1] = zexCraftNftRequests[_requestId].randomness.toString();
    args[2] = block.chainid.toString();
    args[3] = seed;
    args[4]=tokenIdCounter.toString();

    FunctionsRequest.Request memory req;
    req.initializeRequestForInlineJavaScript(sourceCode);
    if (encryptedSecretsUrls.length > 0)
      req.addSecretsReference(encryptedSecretsUrls);
    else if (donHostedSecretsVersion > 0) {
      req.addDONHostedSecrets(donHostedSecretsSlotID,donHostedSecretsVersion);
    }
    req.setArgs(args);
    
    s_lastRequestId = _sendRequest(req.encodeCBOR(), subscriptionId, s_callbackGasLimit, donId);
    functionToVRFRequest[s_lastRequestId] = _requestId;
    zexCraftNftRequests[_requestId].status = Status.FUNCTIONS_REQUESTED;
    tokenIdCounter+=1;
  }

  function mintBabyZexCraftNft(
    uint256 _requestId,
    string memory seed,
   bytes memory encryptedSecretsUrls,
    uint8 donHostedSecretsSlotID,
    uint64 donHostedSecretsVersion,
    string[] memory args,
    uint64 subscriptionId
  ) public  {
    // TODO : add onlyRelationshipOrCrosschain modifier
    require(zexCraftNftRequests[_requestId].status == Status.NFT_REQUESTED, "request not found");
    require(msg.sender == zexCraftNftRequests[_requestId].owner, "not owner");
    zexCraftNftRequests[_requestId].tokenId= tokenIdCounter;

    args[0] = "BREEDING";
    args[1] = zexCraftNftRequests[_requestId].nft1.tokenURI;
    args[2] = zexCraftNftRequests[_requestId].nft1.chainId.toString();
    args[3] = zexCraftNftRequests[_requestId].nft2.tokenURI;
    args[4] = zexCraftNftRequests[_requestId].nft2.chainId.toString();
    args[5] = zexCraftNftRequests[_requestId].randomness.toString();
    args[6] = seed;
    args[7]=tokenIdCounter.toString();

    FunctionsRequest.Request memory req;
    req.initializeRequestForInlineJavaScript(sourceCode);
    if (encryptedSecretsUrls.length > 0)
      req.addSecretsReference(encryptedSecretsUrls);
    else if (donHostedSecretsVersion > 0) {
      req.addDONHostedSecrets(donHostedSecretsSlotID,donHostedSecretsVersion);
    }
    req.setArgs(args);
    s_lastRequestId = _sendRequest(req.encodeCBOR(), subscriptionId, s_callbackGasLimit, donId);
    functionToVRFRequest[s_lastRequestId] = _requestId;
    zexCraftNftRequests[_requestId].status = Status.FUNCTIONS_REQUESTED;
    tokenIdCounter+=1;
  }



  function getRequestStatus(
    uint256 _requestId
  ) external view returns (uint256 paid, bool fulfilled, uint256 randomWords) {
    require(s_requests[_requestId].paid > 0, "request not found");
    RequestStatus memory request = s_requests[_requestId];
    return (request.paid, request.fulfilled, request.randomWord);
  }

  function withdrawLink() public onlyOwner {
    LinkTokenInterface link = LinkTokenInterface(linkAddress);
    require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
  }



  /**
   * @notice Store latest result/error
   * @param requestId The request ID, returned by sendRequest()
   * @param response Aggregated response from the user code
   * @param err Aggregated error from the user code or from the execution pipeline
   * Either response or error parameter will be set, but never both
   */
  function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
    if (response.length > 0) {
      string memory tokenUri = string(response);
      uint256 _requestId = functionToVRFRequest[requestId];
      uint256 _tokenIdCounter = zexCraftNftRequests[_requestId].tokenId;
      _safeMint(zexCraftNftRequests[_requestId].owner, _tokenIdCounter);
      _setTokenURI(_tokenIdCounter, tokenUri);
      zexCraftNftRequests[_requestId].status = Status.MINTED;
      emit ZexCraftNFTCreated(_tokenIdCounter, tokenUri, zexCraftNftRequests[_requestId].owner);
    }else{
      emit OracleReturned(requestId, response, err);
    }
  }

  function deployZexNFTAccount(uint256 _tokenId) external {
      require(ownerOf(_tokenId) == msg.sender, "not owner");
    require(zexCraftNftRequests[tokenIdToZexCraftNftRequest[_tokenId]].status == Status.MINTED, "not minted");
    require(zexCraftNftRequests[tokenIdToZexCraftNftRequest[_tokenId]].account == address(0), "already deployed");
    _deployAccount(address(this),_tokenId);
  }

  function deployOtherNFTAccount(address tokenAddress, uint256 _tokenId) external payable {
    require(msg.value>=mintFee,"not enough fee");
    require(IERC721(tokenAddress).ownerOf(_tokenId) == msg.sender, "not owner");
    _deployAccount(tokenAddress,_tokenId);
  }


  
  function _deployAccount(address tokenAddress, uint256 _tokenId) internal{
    address account=registry.account(erc6551Implementation, block.chainid, tokenAddress, _tokenId, 0);
    require(accounts[account]==false,"already deployed");
    account = registry.createAccount{value: 0}(erc6551Implementation, block.chainid, tokenAddress, _tokenId, 0, "0x");
    zexCraftNftRequests[tokenIdToZexCraftNftRequest[_tokenId]].account = account;
    accounts[account]=true;
    emit ZexCraftAccountDeployed(tokenAddress,_tokenId,account);
  }

  /**
   * @notice Set the Callback Gas Limit
   * @param _callbackGasLimit New Callback Gas Limit
   */
  function setCallbackGasLimit(uint32 _callbackGasLimit) external onlyOwner {
    s_callbackGasLimit = _callbackGasLimit;
  }

  /**
   * @notice Set the DON ID
   * @param newDonId New DON ID
   */
  function setDonId(bytes32 newDonId) external onlyOwner {
    donId = newDonId;
  }

  // The following functions are overrides required by Solidity.

  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    return super.tokenURI(tokenId);
  }

   function supportsInterface(bytes4 interfaceId) public view override(ERC721) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
 


  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function getStatus(uint requestId) public view returns (Status) {
    return zexCraftNftRequests[requestId].status;
  }
}
