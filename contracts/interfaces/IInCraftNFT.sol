// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IRelationship.sol";

interface IInCraftNFT {
  function createBaby(NFT memory nft1, NFT memory nft2) external returns (uint256);
}
