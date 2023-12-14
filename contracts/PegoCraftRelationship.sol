// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";

import "./interfaces/IZexCraftNFT.sol";
import "./interfaces/IRelationship.sol";
import "./interfaces/IERC6551Account.sol";

contract ZexCraftRelationship is CCIPReceiver, ConfirmedOwner {
  uint256 public state;

  IRelationship.NFT[2] public nfts;

  address public zexCraftAddress;

  bool public isInitialized;
  bytes32 public s_lastReceivedMessageId;
  bytes public s_lastReceivedData;
  address public router;
  uint256 public crosschainMintFee;
  mapping(uint64 => mapping(address => bool)) public allowlistedAddresses;
  mapping(uint256 => uint8) public babyRequests;

  constructor(
    address _router,
    uint mintFee,
    address _zexCraftAddress
  ) CCIPReceiver(_router) ConfirmedOwner(msg.sender) {
    router = _router;
    crosschainMintFee = mintFee;
    zexCraftAddress = _zexCraftAddress;
  }

  event MessageReceived(bytes32 messageId, bytes data);
  event OperationFailed();

  modifier onlyAllowlisted(uint64 sourceChainSelector, address sender) {
    require(allowlistedAddresses[sourceChainSelector][sender] == true, "not allowlisted");
    _;
  }

  modifier onlyOnce() {
    require(!isInitialized, "already initialized");
    _;
    isInitialized = true;
  }

  function intialize(IRelationship.NFT memory nft1, IRelationship.NFT memory nft2) external onlyOnce {
    nfts[0] = nft1;
    nfts[1] = nft2;
    allowlistedAddresses[nft1.sourceChainSelector][nft1.contractAddress] = true;
    allowlistedAddresses[nft2.sourceChainSelector][nft2.contractAddress] = true;
  }

  function isValidSigner(address signer) external view returns (bool) {
    return _isValidSigner(signer);
  }

  function _isValidSigner(address signer) internal view returns (bool) {
    return
      IERC6551Account(payable(nfts[1].contractAddress)).isSigner(signer) ||
      IERC6551Account(payable(nfts[1].contractAddress)).isSigner(signer);
  }

  function execute(
    address to,
    uint256 value,
    bytes calldata data,
    uint8 operation,
    bytes[2] memory signatures
  ) external payable virtual returns (bytes memory result) {
    // TODO: Check if both the signatures are valid
    require(_isValidSigner(msg.sender), "Invalid sender");
    require(operation == 0, "Only call operations are supported");
    ++state;

    bool success;
    (success, result) = to.call{value: value}(data);

    if (!success) {
      assembly {
        revert(add(result, 32), mload(result))
      }
    }
  }

  function createBaby(bytes memory parterSig) external payable returns (uint256) {
    // TODO: Verify partner signature
    require(_isValidSigner(msg.sender), "Invalid signer");
    uint256 requestId = IZexCraftNFT(zexCraftAddress).createBabyZexCraftNft{value: msg.value}(nfts[0], nfts[1]);
    babyRequests[requestId] = 1;
    return requestId;
  }

  function createBabyAccount(uint256 requestId) public returns (address) {
    require(_isValidSigner(msg.sender), "Invalid signer");
    require(babyRequests[requestId] == 1, "invalid requestId");
    babyRequests[requestId] = 2;

    return IZexCraftNFT(zexCraftAddress).deployBabyZexCraftNftAccount(requestId);
  }

  function _ccipReceive(
    Client.Any2EVMMessage memory any2EvmMessage
  )
    internal
    override
    onlyAllowlisted(any2EvmMessage.sourceChainSelector, abi.decode(any2EvmMessage.sender, (address)))
  {
    (address sender, ) = abi.decode(any2EvmMessage.data, (address, bytes));
    // TODO: Verify partner sig
    require(_isValidSigner(sender), "Invalid signer");
    IZexCraftNFT(zexCraftAddress).createBabyZexCraftNftCrosschain(nfts[0], nfts[1]);

    s_lastReceivedData = any2EvmMessage.data;
    s_lastReceivedMessageId = any2EvmMessage.messageId;
    emit MessageReceived(any2EvmMessage.messageId, any2EvmMessage.data);
  }

  function getParents() external view returns (address parent1, address parent2) {
    parent1 = nfts[0].contractAddress;
    parent2 = nfts[1].contractAddress;
  }
}
