// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ICraftToken {
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function permit(address owner, uint256 amount, address spender, uint256 deadline, bytes memory signature) external;
  function balanceOf(address account) external view returns (uint256);
}
