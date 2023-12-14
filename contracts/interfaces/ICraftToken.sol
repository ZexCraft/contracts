// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ICrafToken {
  function burnTokens(address creator, uint256 amount) external returns (bool);
}
