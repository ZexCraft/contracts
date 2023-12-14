// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Create2.sol";
import "./interfaces/IERC6551Registry.sol";
import "./interfaces/IRelationship.sol";
import "./interfaces/IERC6551Account.sol";
import "./interfaces/IERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ZexCraftRelationshipRegistry is Ownable {
  mapping(address => bool) public relationshipExists;

  IERC6551Registry public accountRegistry;
  address public relationshipImplementation;

  mapping(address => mapping(address => bool)) public pairs;

  constructor(IERC6551Registry _accountRegistry) Ownable(msg.sender) {
    accountRegistry = _accountRegistry;
  }

  event RelationshipCreated(NFT nft1, NFT nft2, address relationship);

  modifier onlyZexCraftERC6551Account(address otherAccount) {
    require(accountRegistry.isAccount(msg.sender), "TxSender not account");
    require(accountRegistry.isAccount(otherAccount), "Pair not account");
    _;
  }

  function setRelationshipImplementation(address _relationshipImplementation) public onlyOwner {
    relationshipImplementation = _relationshipImplementation;
  }

  function createRelationship(
    address otherAccount,
    bytes memory otherAccountsignature
  ) external onlyZexCraftERC6551Account(otherAccount) returns (address) {
    NFT memory nft1 = _getNft(msg.sender);
    NFT memory nft2 = _getNft(otherAccount);
    return _createRelationship(nft1, nft2, otherAccountsignature);
  }

  function _createRelationship(
    NFT memory nft1,
    NFT memory nft2,
    bytes memory otherAccountsignature
  ) internal returns (address) {
    require(pairs[nft1.tokenAddress][nft2.tokenAddress] == false, "pair already exists");
    require(relationshipImplementation != address(0), "relationshipImplementation not set");
    // TODO: Verify otherAccountsignature with owner of the other NFT using owner() function of ERC6551
    address relationship = _deployProxy(relationshipImplementation, 1);
    require(relationshipExists[relationship] == false, "Relationship already exists");

    IRelationship(relationship).initialize(nft1, nft2);
    relationshipExists[relationship] = true;
    pairs[nft1.tokenAddress][nft2.tokenAddress] = true;
    pairs[nft2.tokenAddress][nft1.tokenAddress] = true;
    emit RelationshipCreated(nft1, nft2, relationship);

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

  function _getNft(address account) internal view returns (NFT memory) {
    (uint256 chainId, address nftAddress, uint256 tokenId) = IERC6551Account(payable(account)).token();
    return NFT(nftAddress, tokenId, chainId);
  }

  function isRelationship(address _address) external view returns (bool) {
    return relationshipExists[_address];
  }
}
