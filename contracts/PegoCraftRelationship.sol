// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IRelationship.sol";
import "./interfaces/IERC6551Account.sol";
import "./interfaces/IPegoCraftNFT.sol";

contract ZexCraftRelationship {
  uint256 public state;

  NFT[2] public nfts;

  address public pegoCraft;

  bool public isInitialized;

  modifier onlyOnce() {
    require(!isInitialized, "already initialized");
    _;
    isInitialized = true;
  }

  function intialize(NFT memory nft1, NFT memory nft2, address _pegoCraft) external onlyOnce {
    nfts[0] = nft1;
    nfts[1] = nft2;
    pegoCraft = _pegoCraft;
  }

  function isValidSigner(address signer) external view returns (bool) {
    return _isValidSigner(signer);
  }

  function _isValidSigner(address signer) internal view returns (bool) {
    return
      IERC6551Account(payable(nfts[1].tokenAddress)).isSigner(signer) ||
      IERC6551Account(payable(nfts[1].tokenAddress)).isSigner(signer);
  }

  function execute(
    address to,
    uint256 value,
    bytes calldata data,
    uint8 operation,
    bytes memory signatures
  ) external payable virtual returns (bytes memory result) {
    // TODO: Check if both the signatures are valid
    require(_isValidSigner(msg.sender), "Invalid sender");
    require(operation == 0, "Only call operations are supported");
    ++state;

    bool success;
    (success, result) = to.call{value: value}(data);

    if (!success) {
      assembly {
        revert(add(result, 32), mload(result))
      }
    }
  }

  function getSignData(
    address relationship,
    uint256 timstamp,
    string memory tokenUri
  ) external pure returns (bytes memory) {
    return abi.encode(relationship, timstamp, tokenUri);
  }
}
