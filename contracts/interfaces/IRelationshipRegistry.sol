// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IRelationshipRegistry{


    function isRelationship(address _address) external view returns (bool);
}