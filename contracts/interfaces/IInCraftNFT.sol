// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IRelationship.sol";

interface IInCraftNFT {
  function createBaby(
    address parent1,
    address parent2,
    address relationship,
    string memory tokenURI
  ) external returns (address);
}
