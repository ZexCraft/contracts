// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Create2.sol";
import "./interfaces/IERC6551Registry.sol";
import "./interfaces/IRelationship.sol";
import "./interfaces/IERC6551Account.sol";
import "./interfaces/IERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract ZexCraftRelationshipRegistry {
  using ECDSA for bytes32;
  using MessageHashUtils for bytes32;
  uint256 public nonce;
  mapping(address => bool) public relationshipExists;

  IERC6551Registry public accountRegistry;
  address public relationshipImplementation;
  uint256 public mintFee;
  address public devWallet;
  address public craftToken;
  string public constant ZEXCRAFT_CREATE_RELATIONSHIP="ZEXCRAFT_CREATE_RELATIONSHIP";

  mapping(address => mapping(address => bool)) public pairs;

  address public zexCraft;

  constructor(IERC6551Registry _accountRegistry, address _relationshipImplementation, uint256 _mintFee) {
    relationshipImplementation = _relationshipImplementation;
    accountRegistry = _accountRegistry;
    devWallet = msg.sender;
    mintFee = _mintFee;
  }

  event RelationshipCreated(address parent1, address parent2, address relationship);

  modifier onlyZexCraftERC6551Account(address otherAccount) {
    require(accountRegistry.isAccount(msg.sender), "TxSender not account");
    require(accountRegistry.isAccount(otherAccount), "Pair not account");
    _;
  }

  modifier onlyDev() {
    require(msg.sender == devWallet, "only dev");
    _;
  }

  function initialize(address _zexCraft, address _craftToken) external onlyDev {
    require(zexCraft == address(0), "Already intialized");
    zexCraft = _zexCraft;
    craftToken = _craftToken;
  }

  function createRelationship(
    address otherAccount,
    bytes memory otherAccountsignature
  ) external onlyZexCraftERC6551Account(otherAccount) returns (address) {
    address nft2Owner = IERC6551Account(payable(otherAccount)).owner();
    bytes32 messageHash = keccak256(abi.encodePacked(ZEXCRAFT_CREATE_RELATIONSHIP,msg.sender, otherAccount));
    address signer = messageHash.toEthSignedMessageHash().recover(otherAccountsignature);
    require(signer == nft2Owner, "Invalid signature");

    return _createRelationship(msg.sender, otherAccount);
  }

  function _createRelationship(
    address breedingAccount,
    address otherAccount
  ) internal returns (address) {
    require(zexCraft != address(0), "Not intialized");
    require(pairs[breedingAccount][otherAccount] == false, "pair already exists");
    require(relationshipImplementation != address(0), "impl not set");

    address relationship = _deployProxy(relationshipImplementation, nonce);
    require(relationshipExists[relationship] == false, "Relationship already exists");

    IRelationship(relationship).initialize([breedingAccount, otherAccount], devWallet, craftToken, mintFee, zexCraft);
    relationshipExists[relationship] = true;
    pairs[breedingAccount][otherAccount] = true;
    pairs[otherAccount][breedingAccount] = true;
    emit RelationshipCreated(breedingAccount, otherAccount, relationship);
    nonce++;
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

  function account(
    uint256 salt
  ) external view returns (address) {
    return _account(salt);
  }

  function _account(uint256 _nonce) internal view returns (address) {
    bytes memory code = _creationCode(relationshipImplementation, _nonce);
    return Create2.computeAddress(bytes32(_nonce), keccak256(code));
  }

  function isRelationship(address _address) external view returns (bool) {
    return relationshipExists[_address];
  }
}
