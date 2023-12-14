// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ICraftToken {
  function burnTokens(address creator, uint256 amount) external returns (bool);
}
