// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IRelationship.sol";
import "./interfaces/IERC6551Account.sol";
import "./interfaces/IInCraftNFT.sol";
import "./interfaces/ICraftToken.sol";

import "./interfaces/INFT.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract InCraftRelationship is IRelationship {
  using ECDSA for bytes32;
  using MessageHashUtils for bytes32;
  uint256 public state;

  uint256 public nonce;

  address[2] public nfts;

  address public inCraft;
  address public devWallet;
  address public craftToken;
  uint256 public mintFee;
  bool public isInitialized;

  string public constant MINT_ACTION = "INCRAFT_MINT";

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
    uint256 _mintFee,
    address _inCraft,
    address _craftToken
  ) external onlyOnce {
    nfts = _nfts;
    inCraft = _inCraft;
    devWallet = _devWallet;
    mintFee = _mintFee;
    craftToken = _craftToken;
    isInitialized = true;
  }

  function execute(
    address to,
    uint256 value,
    bytes calldata data,
    uint8 operation,
    bytes[2] memory signatures
  ) external payable virtual returns (bytes memory result) {
    // TODO: Check if both the signatures are valid

    require(to != inCraft, "Only dev wallet");
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

  function verifySignature(address creator, bytes32 dataHash, bytes memory signature) public pure returns (bool) {
    address signer = dataHash.toEthSignedMessageHash().recover(signature);
    return signer == creator;
  }

  function createBaby(bytes[2] memory signatures) external onlyDev {
    bytes32 dataHash = getSignData();
    require(verifySignature(nfts[0], dataHash, signatures[0]), "invalid signature");
    require(ICraftToken(craftToken).balanceOf(address(this)) >= mintFee, "not enough fee");
    ICraftToken(craftToken).transferFrom(address(this), inCraft, mintFee);

    (, address nft1TokenAddress, uint256 nft1TokenId) = IERC6551Account(payable(nfts[0])).token();
    (, address nft2TokenAddress, uint256 nft2TokenId) = IERC6551Account(payable(nfts[1])).token();
    nonce++;
    string memory nft1TokenUri = INFT(nft1TokenAddress).tokenURI(nft1TokenId);
    string memory nft2TokenUri = INFT(nft2TokenAddress).tokenURI(nft2TokenId);
    IInCraftNFT(inCraft).createBaby(nfts[0], nfts[1], nft1TokenUri, nft2TokenUri);
  }

  function getSignData() public view returns (bytes32) {
    return keccak256(abi.encodePacked(MINT_ACTION, address(this), nonce));
  }

  function getParents() external view returns (address, address) {
    return (nfts[0], nfts[1]);
  }
}
