// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFV2WrapperConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NounsZexCraftNFT is ERC721, ERC721URIStorage, VRFV2WrapperConsumerBase, FunctionsClient, ConfirmedOwner {
  using Strings for uint256;
  using FunctionsRequest for FunctionsRequest.Request;

  enum Status {
    DOES_NOT_EXIST,
    REQUESTED,
    NOUN_CREATED,
    ZEXNOUN_REQUESTED,
    MINTED
  }

  struct RequestStatus {
    uint256 paid; // amount paid in link
    bool fulfilled; // whether the request has been successfully fulfilled
    uint256 randomWord;
  }

  struct NewZexNounRequest {
    string prompt;
    string nounUri;
    string tokenUri;
    uint256 requestId;
    uint256 tokenId;
    uint256 randomness;
    address creator;
    Status status;
  }

  struct BabyZexNounRequest {
    uint256 nounTokenId;
    uint256 chainId;
    address tokenAddress;
    string tokenUri;
    uint256 tokenId;
    uint256 randomness;
    address creator;
    Status status;
  }

  // Chainlink Functions Variables
  bytes32 public donId; // DON ID for the Functions DON to which the requests are sent

  bytes32 public s_lastRequestId;
  bytes public s_lastResponse;
  bytes public s_lastError;
  uint32 public s_callbackGasLimit;
  string public sourceCode;

  // ZexCraftNFT Variables
  address public relRegisty;
  uint256 public mintFee;
  address public linkAddress;
  address public wrapperAddress;
  mapping(uint256 => NewZexNounRequest) public newZexNounRequests;
  mapping(uint256 => BabyZexNounRequest) public babyZexNounRequests;
  mapping(bytes32 => uint256) public functionToVRFRequest;

  // Chainlink VRF Variables
  mapping(uint256 => RequestStatus) public s_requests;

  // past requests Id.
  uint256[] public requestIds;
  uint256 public lastRequestId;

  uint32 v_callbackGasLimit = 100000;
  uint16 public constant requestConfirmations = 3;
  uint32 public constant numWords = 1;

  constructor(
    address _linkAddress,
    address _wrapperAddress,
    address router,
    bytes32 _donId,
    address _relRegisty,
    string memory _sourceCode,
    uint32 _callbackGasLimit,
    uint256 _mintFee
  )
    ERC721("ZexNouns", "ZNOUNS")
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
  }

  event OracleReturned(bytes32 requestId, bytes response, bytes error);
  event RequestSent(uint256 requestId, uint32 numWords);
  event RequestFulfilled(uint256 requestId, uint256[] randomWords, uint256 payment, string nounUri);
  event ZexCraftNewNFTCreated(uint256 tokenId, string prompt, string tokenUri, address owner);

  modifier onlyRelRegistry() {
    require(msg.sender == relRegisty, "only rel registry");
    _;
  }

  function createNewZexCraftNft(string memory prompt) public payable onlyOwner returns (uint256 requestId) {
    requestId = requestRandomness(v_callbackGasLimit, requestConfirmations, numWords);
    s_requests[requestId] = RequestStatus({
      paid: VRF_V2_WRAPPER.calculateRequestPrice(v_callbackGasLimit),
      randomWord: 0,
      fulfilled: false
    });
    requestIds.push(requestId);
    lastRequestId = requestId;
    emit RequestSent(requestId, numWords);
    newZexNounRequests[requestId] = NewZexNounRequest({
      prompt: prompt,
      nounUri: "",
      tokenUri: "",
      requestId: requestId,
      randomness: 0,
      tokenId: 0,
      creator: msg.sender,
      status: Status.REQUESTED
    });
    return requestId;
  }

  function createBabyZexCraftNft(
    uint nounTokenId,
    uint chainId,
    address tokenAddress,
    uint tokenId
  ) public onlyRelRegistry returns (uint256 requestId) {
    requestId = requestRandomness(v_callbackGasLimit, requestConfirmations, numWords);
    s_requests[requestId] = RequestStatus({
      paid: VRF_V2_WRAPPER.calculateRequestPrice(v_callbackGasLimit),
      randomWord: 0,
      fulfilled: false
    });
    requestIds.push(requestId);
    lastRequestId = requestId;
    emit RequestSent(requestId, numWords);
    babyZexNounRequests[requestId] = BabyZexNounRequest({
      nounTokenId: nounTokenId,
      chainId: chainId,
      tokenAddress: tokenAddress,
      tokenId: tokenId,
      randomness: 0,
      tokenUri: "",
      creator: msg.sender,
      status: Status.REQUESTED
    });
    return requestId;
  }

  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
    require(s_requests[_requestId].paid > 0, "request not found");
    uint randomWord = _randomWords[0];
    s_requests[_requestId].fulfilled = true;
    s_requests[_requestId].randomWord = randomWord;

    if (newZexNounRequests[_requestId].status == Status.REQUESTED) {
      string memory background = (randomWord % 2).toString();
      randomWord /= 10;
      string memory body = (randomWord % 30).toString();
      randomWord /= 100;
      string memory head = (randomWord % 234).toString();
      randomWord /= 1000;
      string memory accessory = (randomWord % 137).toString();
      randomWord /= 1000;
      string memory glasses = (randomWord % 21).toString();
      randomWord /= 100;

      string memory nounUri = string(
        abi.encodePacked(
          "https://noun-api.com/beta/pfp?head=",
          head,
          "&glasses=",
          glasses,
          "&background=",
          background,
          "&body=",
          body,
          "&accessory=",
          accessory
        )
      );
      newZexNounRequests[_requestId].nounUri = nounUri;
      newZexNounRequests[_requestId].randomness = randomWord % 100;
      newZexNounRequests[_requestId].status = Status.ZEXNOUN_REQUESTED;
      newZexNounRequests[_requestId].tokenId = uint256(keccak256(abi.encodePacked(nounUri)));
      emit RequestFulfilled(_requestId, _randomWords, s_requests[_requestId].paid, nounUri);
    } else {
      babyZexNounRequests[_requestId].randomness = randomWord % 100;
      emit RequestFulfilled(_requestId, _randomWords, s_requests[_requestId].paid, "");
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
  ) public {
    require(babyZexNounRequests[_requestId].status == Status.ZEXNOUN_REQUESTED, "request not found");
    require(msg.sender == babyZexNounRequests[_requestId].creator, "not creator");
    args[0] = "BREEDING";
    args[1] = babyZexNounRequests[_requestId].tokenId.toString();
    args[2] = tokenURI(babyZexNounRequests[_requestId].nounTokenId);
    args[3] = babyZexNounRequests[_requestId].chainId.toString();
    args[4] = uint256(uint160(babyZexNounRequests[_requestId].tokenAddress)).toHexString(20);
    args[5] = babyZexNounRequests[_requestId].tokenId.toString();
    args[6] = babyZexNounRequests[_requestId].randomness.toString();
    args[7] = seed;
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
    require(newZexNounRequests[_requestId].status == Status.NOUN_CREATED, "request not found");
    require(msg.sender == newZexNounRequests[_requestId].creator, "not creator");
    args[0] = "NEW_BORN";
    args[1] = newZexNounRequests[_requestId].tokenId.toString();
    args[2] = newZexNounRequests[_requestId].prompt;
    args[3] = newZexNounRequests[_requestId].nounUri;
    args[4] = newZexNounRequests[_requestId].randomness.toString();
    args[5] = seed;
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
    if (err.length > 0) {
      emit OracleReturned(requestId, response, err);
      return;
    } else {
      uint256 _requestId = functionToVRFRequest[requestId];
      if (newZexNounRequests[_requestId].status == Status.ZEXNOUN_REQUESTED) {
        string memory tokenUri = abi.decode(response, (string));
        newZexNounRequests[_requestId].tokenUri = tokenUri;
        newZexNounRequests[_requestId].status = Status.MINTED;
        uint256 tokenId = newZexNounRequests[_requestId].tokenId;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenUri);
      } else {
        string memory tokenUri = abi.decode(response, (string));
        babyZexNounRequests[_requestId].tokenUri = tokenUri;
        babyZexNounRequests[_requestId].status = Status.MINTED;
        uint256 tokenId = babyZexNounRequests[_requestId].tokenId;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI(babyZexNounRequests[_requestId].nounTokenId));
      }
    }
    s_lastResponse = response;
    s_lastError = err;
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
