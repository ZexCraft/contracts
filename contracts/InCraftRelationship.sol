// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IRelationship.sol";
import "./interfaces/IERC6551Account.sol";
import "./interfaces/IZexCraftNFT.sol";
import "./interfaces/ICraftToken.sol";

import "./interfaces/INFT.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract ZexCraftRelationship is IRelationship {
  using ECDSA for bytes32;
  using MessageHashUtils for bytes32;

  uint256 public state;
  uint256 public nonce;
  address[2] public nfts;

  address public zexCraft;
  address public devWallet;
  ICraftToken public craftToken;
  uint256 public mintFee;
  bool public isInitialized;

  string public constant ZEXCRAFT_BREED = "ZEXCRAFT_BREED";

  modifier onlyOnce() {
    require(!isInitialized, "already initialized");
    _;
    isInitialized = true;
  }

  modifier onlyDev() {
    require(msg.sender == devWallet, "only dev");
    _;
  }

  function initialize(
    address[2] memory _nfts,
    address _devWallet,
    address _craftToken,
    uint256 _mintFee,
    address _zexCraft
  ) external onlyOnce {
    nfts = _nfts;
    zexCraft = _zexCraft;
    devWallet = _devWallet;
    mintFee = _mintFee;
    craftToken = ICraftToken(_craftToken);
    isInitialized = true;
  }

  function execute(
    address to,
    uint256 value,
    bytes calldata data,
    uint8 operation,
    bytes[2] memory signatures
  ) external payable virtual returns (bytes memory result) {
    require(verifySignature(nfts[0], keccak256(data), signatures[0]), "invalid signature 1");
    require(verifySignature(nfts[1], keccak256(data), signatures[1]), "invalid signature 2");
    require(to != zexCraft, "Only dev wallet");
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

  function verifySignature(address nftAccount, bytes32 dataHash, bytes memory signature) public view returns (bool) {
    address signer = dataHash.toEthSignedMessageHash().recover(signature);
    return signer == IERC6551Account(payable(nftAccount)).owner();
  }

  function createBaby(string memory tokenURI, bytes[2] memory signatures) external onlyDev returns (address account) {
    bytes32 dataHash = getSignData();
    require(verifySignature(nfts[0], dataHash, signatures[0]), "invalid nft1 sig");
    require(verifySignature(nfts[1], dataHash, signatures[1]), "invalid nft2 sig");
    require(craftToken.balanceOf(address(this)) >= mintFee, "insufficient fee");

    craftToken.approve(zexCraft, mintFee);
    account = IZexCraftNFT(zexCraft).createBaby(nfts[0], nfts[1], address(this), tokenURI);
    nonce++;

  }

  function getSignData() public view returns (bytes32) {
    return keccak256(abi.encodePacked(ZEXCRAFT_BREED, address(this), nonce));
  }

  function getParents() external view returns (address, address) {
    return (nfts[0], nfts[1]);
  }
}
