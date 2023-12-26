// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import "./interfaces/IRelationshipRegistry.sol";
import "./interfaces/IERC6551Registry.sol";
import "./interfaces/IRelationship.sol";
import "./interfaces/IERC721URIStorage.sol";
import "./interfaces/ICraftToken.sol";

contract ZexCraftNFT is ERC721, ERC721URIStorage {
  using ECDSA for bytes32;
  using MessageHashUtils for bytes32;
  using Strings for uint256;

  bool public isInitialized;
  uint256 public tokenIdCounter;
  IRelationshipRegistry public relRegistry;
  uint256 public mintFee;
  address public craftToken;
  IERC6551Registry public accountRegistry;
  mapping(address => bool) public accounts;
  mapping(uint256 => uint256) public rarity;

  string public constant MINT_ACTION = "ZEXCRAFT_MINT";

  address public operator;

  constructor(address _relRegistry, IERC6551Registry _accountRegistry, uint256 _mintFee) ERC721("ZexCraft", "PCT") {
    relRegistry = IRelationshipRegistry(_relRegistry);
    mintFee = _mintFee;
    tokenIdCounter = 0;
    accountRegistry = _accountRegistry;
    isInitialized = false;
    operator = msg.sender;
  }

  event ZexCraftNFTCreated(
    uint256 tokenId,
    string tokenUri,
    string altImage,
    address owner,
    address account,
    uint256 rarity
  );

  event ZexCraftNFTBred(
    uint256 tokenId,
    string tokenUri,
    string altImage,
    address owner,
    address parent1,
    address parent2,
    address account,
    uint256 rarity
  );

  modifier onlyOperator() {
    require(msg.sender == operator, "only operator");
    _;
  }

  modifier onlyRelationship() {
    require(relRegistry.isRelationship(msg.sender), "only relationship");
    _;
  }

  modifier onlyOnce() {
    require(!isInitialized, "only once");
    _;
    isInitialized = true;
  }

  function setCraftToken(address _craftTokenAddress) public onlyOperator onlyOnce {
    craftToken = _craftTokenAddress;
  }

  function verifySignature(address creator, bytes32 dataHash, bytes memory signature) public pure returns (bool) {
    return recoverSigner(dataHash, signature) == creator;
  }

  function recoverSigner(bytes32 dataHash, bytes memory signature) public pure returns (address) {
    return dataHash.toEthSignedMessageHash().recover(signature);
  }

  function createNft(
    string memory tokenURI,
    string memory altImage,
    address creator,
    bytes memory permitTokensSignature,
    bytes memory createNftSignature
  ) external onlyOperator returns (address account) {
    require(ICraftToken(craftToken).balanceOf(creator) >= mintFee, "not enough fee");
    ICraftToken(craftToken).permit(creator, mintFee, address(this), 2 ** 256 - 1, permitTokensSignature);

    ICraftToken(craftToken).transferFrom(creator, address(this), mintFee);

    bytes32 dataHash = keccak256(abi.encodePacked(MINT_ACTION, tokenURI, altImage, creator));
    require(verifySignature(creator, dataHash, createNftSignature), "invalid signature");

    _mint(creator, tokenIdCounter);
    _setTokenURI(tokenIdCounter, tokenURI);
    account = accountRegistry.createAccount{value: 0}(
      address(0),
      block.chainid,
      address(this),
      tokenIdCounter,
      0,
      bytes("")
    );

    rarity[tokenIdCounter] = uint256(
      keccak256(abi.encodePacked(block.number, block.timestamp, creator, tokenIdCounter))
    )%100;
    emit ZexCraftNFTCreated(tokenIdCounter, tokenURI,altImage, creator, account, rarity[tokenIdCounter]);
    tokenIdCounter++;
  }

  function createBaby(
    address nft1Address,
    address nft2Address,
    address relationship,
    string memory tokenURI,
    string memory altImage
  ) external onlyRelationship returns (address account) {
    require(tx.origin == operator, "only dev owner");
    require(ICraftToken(craftToken).transferFrom(msg.sender, address(this), mintFee), "transfer failed");

    _mint(relationship, tokenIdCounter);
    _setTokenURI(tokenIdCounter, tokenURI);
    account = accountRegistry.createAccount(address(0), block.chainid, address(this), tokenIdCounter, 0, "");
    rarity[tokenIdCounter] = uint256(
      keccak256(abi.encodePacked(block.number, block.timestamp, nft1Address, nft2Address))
    )%100;

    emit ZexCraftNFTBred(
      tokenIdCounter,
      tokenURI,
      altImage,
      relationship,
      nft1Address,
      nft2Address,
      account,
      rarity[tokenIdCounter]
    );

    tokenIdCounter++;
  }

  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    return super.tokenURI(tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}
