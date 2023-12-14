// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contract/access/Ownable.sol";

import "./interfaces/IRelationshipRegistry.sol";
import "./interfaces/IERC6551Registry.sol";
import "./interfaces/IRelationship.sol";
import "./interfaces/IERC721URIStorage.sol";

contract PegoCraft is ERC721, ERC721URIStorage, Ownable {
  using Strings for uint256;

  struct NFT {
    address tokenAddres;
    address tokenId;
    uint256 chainId;
  }

  bool public isInitialized;
  uint256 public tokenIdCounter;
  IRelationshipRegistry public relRegisty;
  uint256 public mintFee;
  address public craftToken;
  IERC6551Registry public accountRegistry;
  mapping(address => bool) public accounts;

  constructor(address _relRegisty, uint256 _mintFee, address _craftToken) ERC721("PegoCraft", "PCT") {
    relRegisty = _relRegisty;
    mintFee = _mintFee;
    tokenIdCounter = 0;
    craftToken = _craftToken;
    isInitialized = false;
  }

  event PegoCraftNFTCreated(uint256 tokenId, string tokenUri, address owner, bool nftType);
  event PegoCraftNFTBred(uint256 tokenId, string tokenUri, address owner, NFT parent1, NFT parent2, bool nftType);

  modifier onlyRelationship() {
    require(relRegisty.isRelationship(msg.sender), "only relationship");
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

  function createNewZexCraftNft(
    string memory tokenURI,
    address creator,
    bytes memory signature
  ) external onlyOwner returns (uint256 requestId) {
    require(IERC20(craftToken).balanceOf(creator) >= mintFee, "not enough fee");
    // Burn the tokens
    _mint(creator, tokenIdCounter);
    _setTokenURI(tokenIdCounter, tokenURI);
    tokenIdCounter++;
    emit PegoCraftNFTCreated(tokenIdCounter, tokenURI, creator, false);
  }

  function createBabyZexCraftNft(
    NFT memory nft1,
    NFT memory nft2,
    string memory tokenURI,
    address relationship,
    bytes memory signature
  ) external onlyOwner returns (uint256 requestId) {
    require(IERC20(craftToken).balanceOf(relationship) >= mintFee, "not enough fee");
    // Burn the tokens
    _mint(creator, tokenIdCounter);
    _setTokenURI(tokenIdCounter, tokenURI);
    tokenIdCounter++;
    emit PegoCraftNFTBred(tokenIdCounter, tokenURI, relationship, nft1, nft2, true);
  }

  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    return super.tokenURI(tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function getStatus(uint requestId) public view returns (Status) {
    return zexCraftNftRequests[requestId].status;
  }
}
