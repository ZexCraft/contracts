// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IRelationship.sol";

interface IZexCraftNFT{

    function createBabyZexCraftNftCrosschain(
        IRelationship.NFT memory nft1,
        IRelationship.NFT memory nft2
    ) external returns (uint256);


    function createNewZexCraftNftCrossChain(
        address creator,
        string memory prompt
    ) external returns (uint256);

}