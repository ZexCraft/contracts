// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Create2.sol";
import "./interfaces/IERC6551Registry.sol";
import "./interfaces/IRelationship.sol";
import "./interfaces/IERC6551Account.sol";
import "./interfaces/IERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract InCraftRelationshipRegistry {
  using ECDSA for bytes32;
  using MessageHashUtils for bytes32;
  mapping(address => bool) public relationshipExists;

  IERC6551Registry public accountRegistry;
  address public relationshipImplementation;
  uint256 public mintFee;
  address public devWallet;

  mapping(address => mapping(address => bool)) public pairs;

  address public inCraft;

  constructor(IERC6551Registry _accountRegistry, address _relationshipImplementation, uint256 _mintFee) {
    relationshipImplementation = _relationshipImplementation;
    accountRegistry = _accountRegistry;
    devWallet = msg.sender;
    mintFee = _mintFee;
  }

  event RelationshipCreated(address parent1, address parent2, address relationship);

  modifier onlyInCraftERC6551Account(address otherAccount) {
    require(accountRegistry.isAccount(msg.sender), "TxSender not account");
    require(accountRegistry.isAccount(otherAccount), "Pair not account");
    _;
  }

  modifier onlyDev() {
    require(msg.sender == devWallet, "only dev");
    _;
  }

  function initialize(address _inCraft, address _craftToken) external onlyDev {
    require(inCraft == address(0), "Already intialized");
    inCraft = _inCraft;
  }

  function createRelationship(
    address otherAccount,
    bytes memory otherAccountsignature
  ) external onlyInCraftERC6551Account(otherAccount) returns (address) {
    // check signatures
    address nft2Owner = IERC6551Account(payable(otherAccount)).owner();
    bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, otherAccount));
    address signer = messageHash.toEthSignedMessageHash().recover(otherAccountsignature);
    require(signer == otherAccount, "Invalid signature");

    return _createRelationship(msg.sender, otherAccount, otherAccountsignature);
  }

  function _createRelationship(
    address breedingAccount,
    address otherAccount,
    bytes memory otherAccountsignature
  ) internal returns (address) {
    require(inCraft != address(0), "Not intialized");
    require(pairs[breedingAccount][otherAccount] == false, "pair already exists");
    require(relationshipImplementation != address(0), "relationshipImplementation not set");

    address relationship = _deployProxy(relationshipImplementation, 1);
    require(relationshipExists[relationship] == false, "Relationship already exists");

    IRelationship(relationship).initialize([breedingAccount, otherAccount], devWallet, mintFee, inCraft);
    relationshipExists[relationship] = true;
    pairs[breedingAccount][otherAccount] = true;
    pairs[otherAccount][breedingAccount] = true;
    emit RelationshipCreated(breedingAccount, otherAccount, relationship);

    return relationship;
  }

  function _deployProxy(address implementation, uint salt) internal returns (address _contractAddress) {
    bytes memory code = _creationCode(implementation, salt);
    _contractAddress = Create2.computeAddress(bytes32(salt), keccak256(code));
    if (_contractAddress.code.length != 0) return _contractAddress;

    _contractAddress = Create2.deploy(0, bytes32(salt), code);
  }

  function _creationCode(address implementation_, uint256 salt_) internal pure returns (bytes memory) {
    return
      abi.encodePacked(
        hex"3d60ad80600a3d3981f3363d3d373d3d3d363d73",
        implementation_,
        hex"5af43d82803e903d91602b57fd5bf3",
        abi.encode(salt_)
      );
  }

  function isRelationship(address _address) external view returns (bool) {
    return relationshipExists[_address];
  }
}
