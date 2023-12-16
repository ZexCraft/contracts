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
import "./interfaces/IERC6551Registry.sol";

contract PegoCraftNFT is ERC721, ERC721URIStorage, Ownable {
  using Strings for uint256;

  bool public isInitialized;
  uint256 public tokenIdCounter;
  IRelationshipRegistry public relRegistry;
  uint256 public mintFee;
  address public craftToken;
  IERC6551Registry public accountRegistry;
  mapping(address => bool) public accounts;
  mapping(uint256 => uint256) public rarity;

  constructor(
    address _relRegistry,
    address accountRegistry,
    uint256 _mintFee
  ) ERC721("PegoCraft", "PCT") Ownable(msg.sender) {
    relRegistry = IRelationshipRegistry(_relRegistry);
    mintFee = _mintFee;
    tokenIdCounter = 0;
    isInitialized = false;
  }

  event PegoCraftNFTCreated(
    uint256 tokenId,
    string tokenUri,
    address owner,
    address account,
    uint256 rarity,
    bool nftType
  );

  event PegoCraftNFTBred(
    uint256 tokenId,
    string tokenUri,
    address owner,
    NFT parent1,
    NFT parent2,
    address account,
    uint256 rarity,
    bool nftType
  );

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

  function createNft(string memory tokenURI) external returns (address account) {
    require(IERC20(craftToken).allowance(msg.sender, address(this)) >= mintFee, "not enough fee");
    require(ICraftToken(craftToken).burnTokens(msg.sender, mintFee), "burn failed");
    _mint(msg.sender, tokenIdCounter);
    _setTokenURI(tokenIdCounter, tokenURI);
    // account = IERC6551Registry(accountRegistry).createAccount(
    //   address(0),
    //   block.chainid,
    //   address(this),
    //   tokenIdCounter,
    //   0,
    //   ""
    // );
    rarity[tokenIdCounter] = uint256(
      keccak256(abi.encodePacked(block.number, block.timestamp, msg.sender, tokenIdCounter))
    );
    tokenIdCounter++;
    emit PegoCraftNFTCreated(tokenIdCounter, tokenURI, msg.sender, account, rarity[tokenIdCounter], false);
  }

  function createBaby(
    NFT memory nft1,
    NFT memory nft2,
    string memory tokenURI,
    bytes memory createBabyData,
    bytes memory signatures
  ) external returns (address account) {
    // check singatures
    // Change msg.sender after decoding the data
    require(IERC20(craftToken).balanceOf(msg.sender) >= mintFee, "not enough fee");
    require(ICraftToken(craftToken).burnTokens(msg.sender, mintFee), "burn failed");
    _mint(msg.sender, tokenIdCounter);
    _setTokenURI(tokenIdCounter, tokenURI);
    account = IERC6551Registry(accountRegistry).createAccount(
      address(0),
      block.chainid,
      address(this),
      tokenIdCounter,
      0,
      ""
    );
    rarity[tokenIdCounter] = uint256(blockhash(block.number - 1));
    tokenIdCounter++;
    emit PegoCraftNFTBred(tokenIdCounter, tokenURI, msg.sender, nft1, nft2, account, rarity[tokenIdCounter], true);
  }

  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    return super.tokenURI(tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}
