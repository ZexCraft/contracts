// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface INFT {
  function tokenURI(uint256 tokenId) external view returns (string memory);
}
