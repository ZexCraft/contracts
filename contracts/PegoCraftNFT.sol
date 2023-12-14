// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IRelationshipRegistry.sol";
import "./interfaces/IERC6551Registry.sol";
import "./interfaces/IRelationship.sol";
import "./interfaces/IERC721URIStorage.sol";
import "./interfaces/ICraftToken.sol";

contract PegoCraft is ERC721, ERC721URIStorage, Ownable {
  using Strings for uint256;

  bool public isInitialized;
  uint256 public tokenIdCounter;
  IRelationshipRegistry public relRegistry;
  uint256 public mintFee;
  address public craftToken;
  IERC6551Registry public accountRegistry;
  mapping(address => bool) public accounts;

  constructor(
    address _relRegistry,
    uint256 _mintFee,
    address _craftToken
  ) ERC721("PegoCraft", "PCT") Ownable(msg.sender) {
    relRegistry = IRelationshipRegistry(_relRegistry);
    mintFee = _mintFee;
    tokenIdCounter = 0;
    craftToken = _craftToken;
    isInitialized = false;
  }

  event PegoCraftNFTCreated(uint256 tokenId, string tokenUri, address owner, bool nftType);
  event PegoCraftNFTBred(uint256 tokenId, string tokenUri, address owner, NFT parent1, NFT parent2, bool nftType);

  modifier onlyRelationship() {
    require(relRegistry.isRelationship(msg.sender), "only relationship");
    _;
  }

  modifier onlyOnce() {
    require(!isInitialized, "only once");
    _;
    isInitialized = true;
  }

  function setCraftToken(address _craftTokenAddress) public onlyOwner onlyOnce {
    craftToken = _craftTokenAddress;
  }

  function createNft(
    string memory tokenURI,
    address creator,
    bytes memory signature
  ) external onlyOwner returns (uint256 requestId) {
    // Check Signature
    require(IERC20(craftToken).allowance(creator, address(this)) >= mintFee, "not enough fee");
    require(ICraftToken(craftToken).burnTokens(creator, mintFee), "burn failed");
    _mint(creator, tokenIdCounter);
    _setTokenURI(tokenIdCounter, tokenURI);
    tokenIdCounter++;
    emit PegoCraftNFTCreated(tokenIdCounter, tokenURI, creator, false);
  }

  function createBaby(
    NFT memory nft1,
    NFT memory nft2,
    string memory tokenURI,
    bytes memory createBabyData,
    bytes memory signatures
  ) external onlyOwner returns (uint256 requestId) {
    // check singatures

    // Change msg.sender after decoding the data
    require(IERC20(craftToken).balanceOf(msg.sender) >= mintFee, "not enough fee");
    require(ICraftToken(craftToken).burnTokens(msg.sender, mintFee), "burn failed");
    _mint(msg.sender, tokenIdCounter);
    _setTokenURI(tokenIdCounter, tokenURI);
    tokenIdCounter++;
    emit PegoCraftNFTBred(tokenIdCounter, tokenURI, msg.sender, nft1, nft2, true);
  }

  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    return super.tokenURI(tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}
