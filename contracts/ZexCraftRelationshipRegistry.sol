// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/utils/Create2.sol";
import "./interfaces/IERC6551Registry.sol";
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


    function createRelationship(address otherAccount, bytes[2] memory signatures) external onlyZexCraftERC6551Account(otherAccount)   {
        // TODO: Verify signatures with owner of NFTs using owner() function of ERC6551
        address relationship = _deployProxy(relationshipImplementation, 1);
        require(relationshipExists[relationship] == false, "Relationship already exists");

        relationshipExists[relationship] = true;

        emit RelationshipCreated(msg.sender, otherAccount, relationship);
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

    function isRelationship(address _address) external view returns (bool) {
        return relationshipExists[_address];
    }
}