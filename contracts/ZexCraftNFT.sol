// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFV2WrapperConsumerBase.sol";


import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


import "./interfaces/IRelationshipRegistry.sol";
import "./interfaces/IERC6551Registry.sol";
import "./interfaces/IRelationship.sol";
import "./interfaces/ILogAutomation.sol";

contract ZexCraftNFT is ERC721, ERC721URIStorage, VRFV2WrapperConsumerBase, FunctionsClient, ConfirmedOwner , ILogAutomation{
  using Strings for uint256;
  using FunctionsRequest for FunctionsRequest.Request;

  enum Status {
    DOES_NOT_EXIST,
    VRF_REQUESTED,
    GENERATE_REQUESTED,
    FETCH_REQUESTED,
    MINTED
  }

 

  struct ZexCraftNftRequest {
    IRelationship.NFT nft1;
    IRelationship.NFT nft2;
    uint256 requestId;
    uint256 tokenId;
    address owner;
    address account;
    uint8 donHostedSecretsSlotID;
    uint64 donHostedSecretsVersion;
    string[] args;
    string messageId;
    Status status;
  }

  // Chainlink Functions Variables
  bytes32 public donId; // DON ID for the Functions DON to which the requests are sent

  bytes32 public s_lastRequestId;
  bytes public s_lastResponse;
  bytes public s_lastError;
  uint32 public s_callbackGasLimit;
  uint64 public s_subscriptionId;
  string public createSourceCode;
  string public fetchSourceCode;
  uint256 public tokenIdCounter;
  mapping(uint256=>uint256) public tokenIdToZexCraftNftRequest;

  // ZexCraftNFT Variables
  IRelationshipRegistry public relRegisty;
  uint256 public mintFee;
  address public linkAddress;
  address public wrapperAddress;
  IERC6551Registry public accountRegistry;
  mapping(address=>bool) public accounts;
  mapping(uint256 => ZexCraftNftRequest) public zexCraftNftRequests;
  mapping(bytes32 => uint256) public functionToVRFRequest;

  // Chainlink VRF Variables

  // past requests Id.
  uint256[] public requestIds;
  uint256 public lastRequestId;

  uint32 v_callbackGasLimit = 1000000;
  uint16 public constant requestConfirmations = 3;
  uint32 public constant numWords = 1;


  address public crossChainAddress;
 

  struct ConstructorParams{
    address _linkAddress;
    address _wrapperAddress;
    address router;
    bytes32 _donId;
    IRelationshipRegistry _relRegisty;
    string _createSourceCode;
    string _fetchSourceCode;
    uint32 _callbackGasLimit;
    uint256 _mintFee;
    // address _crossChainAddress;
    // IERC6551Registry _registry;
  }


  constructor(
    ConstructorParams memory params
  )
    ERC721("ZexCraft", "ZCT")
    FunctionsClient(params.router)
    VRFV2WrapperConsumerBase(params._linkAddress, params._wrapperAddress)
    ConfirmedOwner(msg.sender)
  {
    donId =params._donId;
    relRegisty = params._relRegisty;
    createSourceCode = params._createSourceCode;
    fetchSourceCode=params._fetchSourceCode;
    s_callbackGasLimit = params._callbackGasLimit;
    mintFee = params._mintFee;
    tokenIdCounter = 1;
    linkAddress = params._linkAddress;
    wrapperAddress = params._wrapperAddress;
    // crossChainAddress = params._crossChainAddress;
    // accountRegistry = params._registry;
  }

  event OracleReturned(bytes32 requestId, bytes response, bytes error);
  event RequestSent(uint256 requestId, uint32 numWords);
  event RequestFulfilled(uint256 requestId, uint256[] randomWords, uint256 payment);
  event ZexCraftNFTCreated(uint256 tokenId, string tokenUri, address owner);
  event ZexCraftAccountDeployed(address tokenAddress, uint256 tokenId, address account);
  event ZexCraftNftRequested(uint256 requestId);
    
  modifier onlyRelationship() {
    require(relRegisty.isRelationship(msg.sender), "only relationship");
    _;
  }

  modifier onlyCrosschain() {
    require(msg.sender==crossChainAddress, "only crosschain");
    _;
  }

  function createNewZexCraftNft(string memory prompt,
    uint8 donHostedSecretsSlotID,
    uint64 donHostedSecretsVersion) external payable returns (uint256 requestId) {
    require(msg.value>=mintFee,"not enough fee");
    return _createNewZexCraftNft(msg.sender,prompt,
     donHostedSecretsSlotID,
     donHostedSecretsVersion);
  }

  function createNewZexCraftNftCrossChain(address owner,string memory prompt, 
    uint8 donHostedSecretsSlotID,
    uint64 donHostedSecretsVersion) external payable onlyCrosschain returns (uint256 requestId) {
    return _createNewZexCraftNft(owner,prompt,  
     donHostedSecretsSlotID,
     donHostedSecretsVersion
     );
  }

  function createBabyZexCraftNft(
    IRelationship.NFT memory nft1,
    IRelationship.NFT memory nft2, 
    uint8 donHostedSecretsSlotID,
    uint64 donHostedSecretsVersion
  ) external payable returns (uint256 requestId) {
    require(msg.value>=mintFee,"not enough fee");
    return _createBabyZexCraftNft(nft1, nft2,
     donHostedSecretsSlotID,
     donHostedSecretsVersion);
  }

  function createBabyZexCraftNftCrosschain(IRelationship.NFT memory nft1,IRelationship.NFT memory nft2,
    uint8 donHostedSecretsSlotID,
    uint64 donHostedSecretsVersion) external onlyRelationship returns (uint256 requestId) {
    return _createBabyZexCraftNft(nft1, nft2,
     donHostedSecretsSlotID,
     donHostedSecretsVersion);
  }


  function _createNewZexCraftNft(address owner,string memory prompt,
    uint8 donHostedSecretsSlotID,
    uint64 donHostedSecretsVersion) internal returns (uint256 requestId) {
    requestId = requestRandomness(v_callbackGasLimit, requestConfirmations, numWords);

    requestIds.push(requestId);
    lastRequestId = requestId;
    emit RequestSent(requestId, numWords);
    string[] memory args = new string[](3);
    args[0] = "NEW_BORN";
    args[1] = prompt;
    args[2] = "";

    zexCraftNftRequests[requestId] = ZexCraftNftRequest({
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
      donHostedSecretsSlotID:donHostedSecretsSlotID,
      donHostedSecretsVersion:donHostedSecretsVersion,
      args:args,
      requestId: requestId,
      tokenId: 0,
      owner:owner,
      messageId:"", 
      account:address(0),
      status: Status.VRF_REQUESTED
    });
    return requestId;
  }



  function _createBabyZexCraftNft(
    IRelationship.NFT memory nft1,
    IRelationship.NFT memory nft2,
    uint8 donHostedSecretsSlotID,
    uint64 donHostedSecretsVersion
  ) internal returns (uint256 requestId) {
    requestId = requestRandomness(v_callbackGasLimit, requestConfirmations, numWords);

    requestIds.push(requestId);
    lastRequestId = requestId;
    emit RequestSent(requestId, numWords);
    string[] memory args = new string[](4);
    args[0] = "BREED";
    args[1] = nft1.tokenURI;
    args[2] = nft2.tokenURI;
    args[3] = "";

    zexCraftNftRequests[requestId] = ZexCraftNftRequest({
    nft1: nft1,
    nft2: nft2,
    donHostedSecretsSlotID:donHostedSecretsSlotID,
    donHostedSecretsVersion:donHostedSecretsVersion,
    args:args,  
    messageId:"", 
    tokenId:0,
    requestId: requestId,
      account:address(0),
    owner:msg.sender,
      status: Status.VRF_REQUESTED
    });
    return requestId;
  }

  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
    zexCraftNftRequests[_requestId].status = Status.GENERATE_REQUESTED;
    zexCraftNftRequests[_requestId].args[zexCraftNftRequests[_requestId].args.length-1] = _randomWords[0].toString();
    emit RequestFulfilled(_requestId, _randomWords, 1);
    _generateZexCraftNft(_requestId);
  }

  function _generateZexCraftNft(
    uint256 _requestId
  ) internal {
    zexCraftNftRequests[_requestId].tokenId=tokenIdCounter;
    string[] memory args = zexCraftNftRequests[_requestId].args;
    uint8 donHostedSecretsSlotID = zexCraftNftRequests[_requestId].donHostedSecretsSlotID;
    uint64 donHostedSecretsVersion = zexCraftNftRequests[_requestId].donHostedSecretsVersion;

    FunctionsRequest.Request memory req;
    req.initializeRequestForInlineJavaScript(createSourceCode);
    if (donHostedSecretsVersion > 0) {
      req.addDONHostedSecrets(donHostedSecretsSlotID,donHostedSecretsVersion);
    }
    req.setArgs(args);
    
    s_lastRequestId = _sendRequest(req.encodeCBOR(), s_subscriptionId, s_callbackGasLimit, donId);
    functionToVRFRequest[s_lastRequestId] = _requestId;
    tokenIdCounter+=1;
  }

  function _fetchZexCraftNft(
    uint256 _requestId
  )internal{
    uint8 donHostedSecretsSlotID = zexCraftNftRequests[_requestId].donHostedSecretsSlotID;
    uint64 donHostedSecretsVersion = zexCraftNftRequests[_requestId].donHostedSecretsVersion;
    string[] memory args = zexCraftNftRequests[_requestId].args;
    if(args.length==3){
      string memory rarity = args[2];
      args = new string[](4);
      args[0] = "NEW_BORN";
      args[1] = rarity;
      args[2] = zexCraftNftRequests[_requestId].messageId;
      args[3] = zexCraftNftRequests[_requestId].tokenId.toString();
    }else{
      string memory rarity = args[3];
      args = new string[](8);
      args[0] = "BREED";
      args[1] = zexCraftNftRequests[_requestId].nft1.tokenURI;
      args[2] = uint256(zexCraftNftRequests[_requestId].nft1.sourceChainSelector).toString();
      args[3] = zexCraftNftRequests[_requestId].nft2.tokenURI;
      args[4] = uint256(zexCraftNftRequests[_requestId].nft2.sourceChainSelector).toString();
      args[5] = rarity;
      args[6] = zexCraftNftRequests[_requestId].messageId;
      args[7] = zexCraftNftRequests[_requestId].tokenId.toString();
    }
    FunctionsRequest.Request memory req;
    req.initializeRequestForInlineJavaScript(fetchSourceCode);
    if (donHostedSecretsVersion > 0) {
      req.addDONHostedSecrets(donHostedSecretsSlotID,donHostedSecretsVersion);
    }
    req.setArgs(args);
    
    s_lastRequestId = _sendRequest(req.encodeCBOR(), s_subscriptionId, s_callbackGasLimit, donId);
    functionToVRFRequest[s_lastRequestId] = _requestId;
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
      uint256 _requestId = functionToVRFRequest[requestId];
      if(zexCraftNftRequests[_requestId].status == Status.GENERATE_REQUESTED){
        string memory messageId = string(response);
        zexCraftNftRequests[_requestId].status = Status.FETCH_REQUESTED;
        zexCraftNftRequests[_requestId].messageId = messageId;
        emit ZexCraftNftRequested(_requestId);
      }else{
        string memory tokenUri = string(response);
        uint256 _tokenIdCounter = zexCraftNftRequests[_requestId].tokenId;
        _safeMint(zexCraftNftRequests[_requestId].owner, _tokenIdCounter);
        _setTokenURI(_tokenIdCounter, tokenUri);
        zexCraftNftRequests[_requestId].status = Status.MINTED;
        emit ZexCraftNFTCreated(_tokenIdCounter, tokenUri, zexCraftNftRequests[_requestId].owner);
      }
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

  function withdrawLink() public onlyOwner {
    LinkTokenInterface link = LinkTokenInterface(linkAddress);
    require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
  }

  
  function _deployAccount(address tokenAddress, uint256 _tokenId) internal{
    address account=accountRegistry.account(address(0), block.chainid, tokenAddress, _tokenId, 0);
    require(accounts[account]==false,"already deployed");
    account = accountRegistry.createAccount{value: 0}(address(0), block.chainid, tokenAddress, _tokenId, 0, "0x");
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
  
  function setSubscriptionId(uint64 subscriptionId) external onlyOwner {
    s_subscriptionId = subscriptionId;
  }

  // Chainlink Log Trigger Upkeeps

   function checkLog(
        Log calldata log,
        bytes memory
    ) external pure returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = true;
        performData = log.data;
    }
    
    function performUpkeep(bytes calldata performData) external override {
      uint256 _requestId = abi.decode(performData, (uint256));
      _fetchZexCraftNft(_requestId);
    }

     function bytes32ToAddress(bytes32 _address) public pure returns (address) {
        return address(uint160(uint256(_address)));
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
