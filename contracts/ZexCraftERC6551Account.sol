// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

import "./interfaces/IERC6551Account.sol";
import "./interfaces/IERC6551Registry.sol";
import "./interfaces/IRelationshipRegistry.sol";
import "./interfaces/IRelationship.sol";

interface IERC6551Executable {
  function execute(
    address to,
    uint256 value,
    bytes calldata data,
    uint8 operation
  ) external payable returns (bytes memory);
}

contract ZexCraftERC6551Account is IERC165, IERC1271, IERC6551Account, IERC6551Executable {
  uint256 public state;

  receive() external payable {}

  function createRelationship(
    address _relationshipRegistry,
    address otherAccount,
    bytes memory otherAccountSignature
  ) external returns (address) {
    require(owner() == msg.sender, "Only token owner");
    return IRelationshipRegistry(_relationshipRegistry).createRelationship(otherAccount, otherAccountSignature);
  }

  function execute(
    address to,
    uint256 value,
    bytes memory data,
    uint8 operation
  ) external payable virtual returns (bytes memory result) {
    return _execute(to, value, data, operation);
  }

  function _execute(
    address to,
    uint256 value,
    bytes memory data,
    uint8 operation
  ) internal virtual returns (bytes memory result) {
    require(_isValidSigner(msg.sender), "Invalid signer");
    ++state;

    bool success;
    (success, result) = to.call{value: value}(data);

    if (!success) {
      assembly {
        revert(add(result, 32), mload(result))
      }
    }
  }

  function isValidSigner(address signer, bytes calldata) external view virtual returns (bytes4) {
    if (_isValidSigner(signer)) {
      return IERC6551Account.isValidSigner.selector;
    }

    return bytes4(0);
  }

  function isValidSignature(bytes32 hash, bytes memory signature) external view virtual returns (bytes4 magicValue) {
    bool isValid = SignatureChecker.isValidSignatureNow(owner(), hash, signature);

    if (isValid) {
      return IERC1271.isValidSignature.selector;
    }

    return bytes4(0);
  }

  function supportsInterface(bytes4 interfaceId) external pure virtual returns (bool) {
    return
      interfaceId == type(IERC165).interfaceId ||
      interfaceId == type(IERC6551Account).interfaceId ||
      interfaceId == type(IERC6551Executable).interfaceId;
  }

  function token() public view virtual returns (uint256, address, uint256) {
    bytes memory footer = new bytes(0x60);

    assembly {
      extcodecopy(address(), add(footer, 0x20), 0x4d, 0x60)
    }

    return abi.decode(footer, (uint256, address, uint256));
  }

  function owner() public view returns (address) {
    (uint256 chainId, address tokenContract, uint256 tokenId) = token();

    return IERC721(tokenContract).ownerOf(tokenId);
  }

  function _isValidSigner(address signer) internal view virtual returns (bool) {
    return signer == owner();
  }

  function isParent(
    IRelationshipRegistry relationshipRegistry,
    IERC6551Registry accountRegistry,
    address signer,
    address parent
  ) public view returns (bool) {
    if (relationshipRegistry.isRelationship(parent)) {
      (address parent1, address parent2) = IRelationship(parent).getParents();
      return
        isParent(relationshipRegistry, accountRegistry, signer, parent1) ||
        isParent(relationshipRegistry, accountRegistry, signer, parent2);
    } else if (accountRegistry.isAccount(parent)) {
      return IERC6551Account(payable(parent)).isSigner(signer);
    } else {
      if (signer == parent) return true;
      else return false;
    }
  }

  function isSigner(address signer) external view returns (bool) {
    return _isValidSigner(signer);
  }
}
