// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IRelationship.sol";

interface IPegoCraftNFT {
  function createBaby(NFT memory nft1, NFT memory nft2) external returns (uint256);
}
