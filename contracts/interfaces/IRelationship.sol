// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

struct NFT {
  address tokenAddress;
  uint256 tokenId;
  uint256 chainId;
}

interface IRelationship {
  function initialize(NFT memory nft1, NFT memory nft2) external;

  function isValidSigner(address signer) external view returns (bool);

  function getParents() external view returns (address, address);
}
