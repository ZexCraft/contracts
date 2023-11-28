// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


interface IRelationship{

   struct NFT{
    uint256 tokenId;
    string tokenURI;
    address ownerDuringMint;
    address contractAddress;
    uint256 chainId;
  }

    function initialize(NFT memory nft1, NFT memory nft2) external;
}