// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./viction/VRC25.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract CraftToken is VRC25 {
  using ECDSA for bytes32;
  using MessageHashUtils for bytes32;
  address public immutable i_zexCraftNftAddress;
  address public devWallet;

  mapping(address => uint256) public nonces;

  constructor(address zexCraftNFT) VRC25("CraftToken", "CFT",18){
    devWallet=msg.sender;
    i_zexCraftNftAddress = zexCraftNFT;
  }

  modifier onlyZexCraftNFT() {
    require(msg.sender == i_zexCraftNftAddress, "Only ZexCraft NFT can mint new tokens");
    _;
  }

  function mint(address to) external {
    _mint(to, 1000000000000000000);
  }

  function _estimateFee(uint256 value) internal view override returns (uint256) {
    return 0;
  }
  function permit(address owner, uint256 amount, address spender, uint256 deadline, bytes memory signature) external {
    require(deadline >= block.timestamp, "expired deadline");
    bytes32 dataHash = keccak256(abi.encodePacked(owner, spender, amount, nonces[owner], deadline));
    require(verifySignature(owner, dataHash, signature), "invalid permit sig");
    _approve(owner, spender, amount);
    nonces[owner] += 1;
  }

  function verifySignature(address creator, bytes32 dataHash, bytes memory signature) public pure returns (bool) {
    address signer = dataHash.toEthSignedMessageHash().recover(signature);
    return signer == creator;
  }
}
