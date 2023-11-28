// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFV2WrapperConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IRelationshipRegistry.sol";
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

  struct NFT{
    uint256 tokenId;
    string tokenURI;
    address ownerDuringMint;
    address contractAddress;
    uint256 chainId;
  }

  struct RequestStatus {
    uint256 paid; // amount paid in link
    bool fulfilled; // whether the request has been successfully fulfilled
    uint256 randomWord;
  }

  struct NewZexCraftNftRequest {
    string prompt;
    string tokenUri;
    uint256 requestId;
    uint256 tokenId;
    uint256 randomness;
    address creator;
    Status status;
  }

  struct BabyZexCraftNftRequest {
    NFT nft1;
    NFT nft2;
    uint256 tokenId;
    string tokenUri;
    uint256 randomness;
    address relationship;
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
  mapping(uint256 => NewZexCraftNftRequest) public newZexCraftNftRequests;
  mapping(uint256 => BabyZexCraftNftRequest) public babyZexCraftNftRequests;
  mapping(bytes32 => uint256) public functionToVRFRequest;

  // Chainlink VRF Variables
  mapping(uint256 => RequestStatus) public s_requests;

  // past requests Id.
  uint256[] public requestIds;
  uint256 public lastRequestId;

  uint32 v_callbackGasLimit = 100000;
  uint16 public constant requestConfirmations = 3;
  uint32 public constant numWords = 1;


  // Chainlink CCIP Variables
  address public crossChainRouterAddress;

  constructor(
    address _linkAddress,
    address _wrapperAddress,
    address router,
    bytes32 _donId,
    IRelationshipRegistry _relRegisty,
    string memory _sourceCode,
    uint32 _callbackGasLimit,
    uint256 _mintFee,
    address _crossChainRouterAddress
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
    crossChainRouterAddress = _crossChainRouterAddress;
  }

  event OracleReturned(bytes32 requestId, bytes response, bytes error);
  event RequestSent(uint256 requestId, uint32 numWords);
  event RequestFulfilled(uint256 requestId, uint256[] randomWords, uint256 payment);
  event ZexCraftNewNFTCreated(uint256 tokenId, string prompt, string tokenUri, address owner);

  modifier onlyRelationshipOrCrosschain() {
    require(relRegisty.isRelationship(msg.sender)||msg.sender==crossChainRouterAddress, "only relationship");
    _;
  }

  function createNewZexCraftNft(string memory prompt) public payable returns (uint256 requestId) {
    return _createNewZexCraftNft(prompt);
  }

  function _createNewZexCraftNft(string memory prompt) internal onlyOwner returns (uint256 requestId) {
    requestId = requestRandomness(v_callbackGasLimit, requestConfirmations, numWords);
    s_requests[requestId] = RequestStatus({
      paid: VRF_V2_WRAPPER.calculateRequestPrice(v_callbackGasLimit),
      randomWord: 0,
      fulfilled: false
    });
    requestIds.push(requestId);
    lastRequestId = requestId;
    emit RequestSent(requestId, numWords);
    newZexCraftNftRequests[requestId] = NewZexCraftNftRequest({
      prompt: prompt,
      tokenUri: "",
      requestId: requestId,
      randomness: 0,
      tokenId: 0,
      creator: msg.sender,
      status: Status.VRF_REQUESTED
    });
    return requestId;
  }

  function createBabyZexCraftNft(
    NFT memory nft1,
    NFT memory nft2
  ) public onlyRelationshipOrCrosschain returns (uint256 requestId) {
    requestId = requestRandomness(v_callbackGasLimit, requestConfirmations, numWords);
    s_requests[requestId] = RequestStatus({
      paid: VRF_V2_WRAPPER.calculateRequestPrice(v_callbackGasLimit),
      randomWord: 0,
      fulfilled: false
    });
    requestIds.push(requestId);
    lastRequestId = requestId;
    emit RequestSent(requestId, numWords);
    babyZexCraftNftRequests[requestId] = BabyZexCraftNftRequest({
    nft1: nft1,
    nft2: nft2,
    tokenId:0,
     tokenUri:"",
     randomness:0,
    relationship:msg.sender,
      status: Status.VRF_REQUESTED
    });
    return requestId;
  }

  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
    require(s_requests[_requestId].paid > 0, "request not found");
    uint randomWord = _randomWords[0];
    s_requests[_requestId].fulfilled = true;
    s_requests[_requestId].randomWord = randomWord;

    if (newZexCraftNftRequests[_requestId].status == Status.VRF_REQUESTED) {
     
      newZexCraftNftRequests[_requestId].randomness = randomWord % 100;
      newZexCraftNftRequests[_requestId].status = Status.NFT_REQUESTED;
      emit RequestFulfilled(_requestId, _randomWords, s_requests[_requestId].paid);
    } else{
      babyZexCraftNftRequests[_requestId].randomness = randomWord % 100;
      babyZexCraftNftRequests[_requestId].status = Status.NFT_REQUESTED;
      emit RequestFulfilled(_requestId, _randomWords, s_requests[_requestId].paid);
    }
  }

  function mintBabyZexCraftNft(
    uint256 _requestId,
    string memory seed,
    FunctionsRequest.Location secretsLocation,
    bytes calldata encryptedSecretsReference,
    string[] memory args,
    bytes[] calldata bytesArgs,
    uint64 subscriptionId
  ) public onlyRelationshipOrCrosschain {
    require(babyZexCraftNftRequests[_requestId].status == Status.NFT_REQUESTED, "request not found");
    require(msg.sender == babyZexCraftNftRequests[_requestId].relationship, "not creator");
    args[0] = "BREEDING";
    args[1] = babyZexCraftNftRequests[_requestId].nft1.tokenId.toString();
    args[2] = babyZexCraftNftRequests[_requestId].nft1.tokenURI;
    args[3] = babyZexCraftNftRequests[_requestId].nft1.chainId.toString();
    args[4] = uint256(uint160(babyZexCraftNftRequests[_requestId].nft1.contractAddress)).toHexString(20);
    args[5] = babyZexCraftNftRequests[_requestId].nft2.tokenId.toString();
    args[6] = babyZexCraftNftRequests[_requestId].nft2.tokenURI;
    args[7] = babyZexCraftNftRequests[_requestId].nft2.chainId.toString();
    args[8] = uint256(uint160(babyZexCraftNftRequests[_requestId].nft2.contractAddress)).toHexString(20);
    args[9] = babyZexCraftNftRequests[_requestId].randomness.toString();
    args[10] = seed;
    FunctionsRequest.Request memory req;
    req.initializeRequest(FunctionsRequest.Location.Inline, FunctionsRequest.CodeLanguage.JavaScript, sourceCode);
    req.secretsLocation = secretsLocation;
    req.encryptedSecretsReference = encryptedSecretsReference;
    if (args.length > 0) {
      req.setArgs(args);
    }
    if (bytesArgs.length > 0) {
      req.setBytesArgs(bytesArgs);
    }
    s_lastRequestId = _sendRequest(req.encodeCBOR(), subscriptionId, s_callbackGasLimit, donId);
    functionToVRFRequest[s_lastRequestId] = _requestId;
    babyZexCraftNftRequests[_requestId].status = Status.FUNCTIONS_REQUESTED;
  }

  function mintNewZexCraftNft(
    uint256 _requestId,
    string memory seed,
    FunctionsRequest.Location secretsLocation,
    bytes calldata encryptedSecretsReference,
    string[] memory args,
    bytes[] calldata bytesArgs,
    uint64 subscriptionId
  ) public {
    require(newZexCraftNftRequests[_requestId].status == Status.NFT_REQUESTED, "request not found");
    require(msg.sender == newZexCraftNftRequests[_requestId].creator, "not creator");
    args[0] = "NEW_BORN";
    args[2] = newZexCraftNftRequests[_requestId].prompt;
    args[3] = newZexCraftNftRequests[_requestId].randomness.toString();
    args[4] = seed;
    FunctionsRequest.Request memory req;
    req.initializeRequest(FunctionsRequest.Location.Inline, FunctionsRequest.CodeLanguage.JavaScript, sourceCode);
    req.secretsLocation = secretsLocation;
    req.encryptedSecretsReference = encryptedSecretsReference;
    if (args.length > 0) {
      req.setArgs(args);
    }
    if (bytesArgs.length > 0) {
      req.setBytesArgs(bytesArgs);
    }
    s_lastRequestId = _sendRequest(req.encodeCBOR(), subscriptionId, s_callbackGasLimit, donId);
    functionToVRFRequest[s_lastRequestId] = _requestId;
    newZexCraftNftRequests[_requestId].status = Status.FUNCTIONS_REQUESTED;
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
    if (!(err.length > 0)) {
      uint256 _tokenIdCounter=tokenIdCounter;
      uint256 _requestId = functionToVRFRequest[requestId];
      if (newZexCraftNftRequests[_requestId].status == Status.FUNCTIONS_REQUESTED) {
        string memory tokenUri = abi.decode(response, (string));
        newZexCraftNftRequests[_requestId].tokenId= _tokenIdCounter;
        newZexCraftNftRequests[_requestId].tokenUri = tokenUri;
        newZexCraftNftRequests[_requestId].status = Status.MINTED;
        _safeMint(msg.sender, _tokenIdCounter);
        _setTokenURI(_tokenIdCounter, tokenUri);
        tokenIdCounter+=1;
      } else {
        string memory tokenUri = abi.decode(response, (string));
        babyZexCraftNftRequests[_requestId].tokenUri = tokenUri;
        babyZexCraftNftRequests[_requestId].status = Status.MINTED;
        babyZexCraftNftRequests[_requestId].tokenId=_tokenIdCounter;
        _safeMint(msg.sender, _tokenIdCounter);
        _setTokenURI(_tokenIdCounter, tokenUri);
        tokenIdCounter+=1;
      }
    }
    s_lastResponse = response;
    s_lastError = err;
      emit OracleReturned(requestId, response, err);
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
}
