// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IRelationshipRegistry {
  function createRelationship(address otherAccount, bytes memory otherAccountsignature) external returns (address);

  function isRelationship(address _address) external view returns (bool);
}
