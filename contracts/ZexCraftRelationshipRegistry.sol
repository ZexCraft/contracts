// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/utils/Create2.sol";
import "./interfaces/IERC6551Registry.sol";
import "./interfaces/IRelationship.sol";
import "./interfaces/IERC6551Account.sol";
import "./interfaces/IERC721.sol";

contract ZexCraftRelationshipRegistry {
    mapping(address => bool) public relationshipExists;

    IERC6551Registry public accountRegistry;
    address public relationshipImplementation;


    constructor(IERC6551Registry _accountRegistry,address _relationshipImplementation)
    {
        accountRegistry = _accountRegistry;
        relationshipImplementation=_relationshipImplementation;
    }

    event RelationshipCreated(address indexed account1, address indexed account2, address indexed relationship);

    modifier onlyZexCraftERC6551Account(address otherAccount) {
        require(accountRegistry.isAccount(msg.sender), "TxSender not account");
        require(accountRegistry.isAccount(otherAccount), "Pair not account");
        _;
    }


    function createRelationship(address otherAccount,  bytes[2] memory signatures) external onlyZexCraftERC6551Account(otherAccount) returns(address)   {
        // TODO: Verify signatures with owner of NFTs using owner() function of ERC6551
        IRelationship.NFT memory nft1=_getNft(msg.sender);
        IRelationship.NFT memory nft2=_getNft(otherAccount);
        
        address relationship = _deployProxy(relationshipImplementation, 1);
        require(relationshipExists[relationship] == false, "Relationship already exists");
        
        IRelationship(relationship).initialize(nft1, nft2);
        relationshipExists[relationship] = true;
        
        emit RelationshipCreated(msg.sender, otherAccount, relationship);

        return relationship;
    }

    function _deployProxy(
        address implementation,
        uint salt
    ) internal returns (address _contractAddress) {
        bytes memory code = _creationCode(implementation, salt);
        _contractAddress = Create2.computeAddress(
            bytes32(salt),
            keccak256(code)
        );
        if (_contractAddress.code.length != 0) return _contractAddress;

        _contractAddress = Create2.deploy(0, bytes32(salt), code);
    }

    function _creationCode(
        address implementation_,
        uint256 salt_
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                hex"3d60ad80600a3d3981f3363d3d373d3d3d363d73",
                implementation_,
                hex"5af43d82803e903d91602b57fd5bf3",
                abi.encode(salt_)
            );
    }

    function _getNft(address account) internal view returns (IRelationship.NFT memory) {
        (uint256 chainId, address nftAddress, uint256 tokenId)=IERC6551Account(payable(account)).token();
        address owner=IERC721(nftAddress).ownerOf(tokenId);
        string memory tokenUri=IERC721(nftAddress).tokenURI(tokenId);
        return IRelationship.NFT(tokenId,tokenUri,owner,nftAddress,chainId);
    }

    function isRelationship(address _address) external view returns (bool) {
        return relationshipExists[_address];
    }
}