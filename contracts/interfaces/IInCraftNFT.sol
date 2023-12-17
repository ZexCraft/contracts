// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IRelationship.sol";

interface IInCraftNFT {
  function createBaby(
    address parent1,
    address parent2,
    string memory parent1TokenURI,
    string memory parent2TokenURI
  ) external returns (uint256);
}
