// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CraftToken is ERC20, ERC20Burnable, Ownable {
  address public immutable i_pegoCraftNftAddress;

  constructor(address pegoCraftNFT) ERC20("CraftToken", "CFT") Ownable(msg.sender) {
    i_pegoCraftNftAddress = pegoCraftNFT;
  }

  modifier onlyPegoCraftNFT() {
    require(msg.sender == i_pegoCraftNftAddress, "Only PegoCraft NFT can mint new tokens");
    _;
  }

  function mint(address to) external {
    _mint(to, 1000000000000000000);
  }

  function burnTokens(address creator, uint256 amount) external onlyPegoCraftNFT returns (bool) {
    burnFrom(creator, amount);
    return true;
  }
}
