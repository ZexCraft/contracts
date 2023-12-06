// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";


import "@openzeppelin/contracts/utils/Create2.sol";
import "./interfaces/IERC6551Registry.sol";
import "./interfaces/IRelationship.sol";
import "./interfaces/IERC6551Account.sol";
import "./interfaces/IERC721URIStorage.sol";

contract ZexCraftRelationshipRegistry is CCIPReceiver, ConfirmedOwner{
    mapping(address => bool) public relationshipExists;

    IERC6551Registry public accountRegistry;
    address public relationshipImplementation;
    address public immutable i_ccipRouter;
  address public crossChainAddress;
  bytes32 public s_lastReceivedMessageId ;
  bytes public  s_lastReceivedData ;

  mapping(address=>mapping(address=>bool)) public pairs;

  uint64 public constant chainSelector=14767482510784806043;


  mapping(uint64 => mapping(address => bool)) public allowlistedAddresses;

    constructor(IERC6551Registry _accountRegistry,address _ccipRouter) CCIPReceiver(_ccipRouter) ConfirmedOwner(msg.sender)
    {
        accountRegistry = _accountRegistry;
        i_ccipRouter=_ccipRouter; 
    }



    

    event RelationshipCreated(IRelationship.NFT nft1, IRelationship.NFT nft2, address relationship);


    modifier onlyZexCraftERC6551Account(address otherAccount) {
        require(accountRegistry.isAccount(msg.sender), "TxSender not account");
        require(accountRegistry.isAccount(otherAccount), "Pair not account");
        _;
    }

  modifier onlyAllowlisted(uint64 sourceChainSelector,address sender)
  {
    require(allowlistedAddresses[sourceChainSelector][sender]==true,"not allowlisted");
    _;
  }

    function setRelationshipImplementation(address _relationshipImplementation) public onlyOwner{
        relationshipImplementation=_relationshipImplementation;
    }
    
    function addZexCraftCrossChain(uint64[] memory sourceChainSelector,address[] memory sender) external onlyOwner {
    require(sourceChainSelector.length==sender.length,"invalid length");
    for(uint i=0;i<sourceChainSelector.length;i++)
    {
      allowlistedAddresses[sourceChainSelector[i]][sender[i]]=true;
    }
  }

 
   function _ccipReceive(
        Client.Any2EVMMessage memory any2EvmMessage
  )
        internal
        override
        onlyAllowlisted(
            any2EvmMessage.sourceChainSelector,
            abi.decode(any2EvmMessage.sender, (address))
        ) 
    {
        (IRelationship.NFT memory nft1,IRelationship.NFT memory nft2,bytes memory partnerSig)=abi.decode(any2EvmMessage.data, (IRelationship.NFT,IRelationship.NFT,bytes));
        if(nft1.chainId==block.chainid)
        {
            nft1=_getNft(nft1.contractAddress);
        }
        address relationship=_createRelationship(nft1, nft2,partnerSig);
        s_lastReceivedMessageId = any2EvmMessage.messageId;
        s_lastReceivedData = any2EvmMessage.data;
        emit RelationshipCreated(nft1, nft2, relationship);
    }



    function createRelationship(address otherAccount,  bytes memory otherAccountsignature) external onlyZexCraftERC6551Account(otherAccount) returns(address)   {
         IRelationship.NFT memory nft1=_getNft(msg.sender);
        IRelationship.NFT memory nft2=_getNft(otherAccount);
        return _createRelationship(nft1,nft2,otherAccountsignature);
    }

    function _createRelationship(IRelationship.NFT memory nft1,IRelationship.NFT memory nft2,bytes memory otherAccountsignature) internal returns(address)
    {      
        require(pairs[nft1.contractAddress][nft2.contractAddress]==false,"pair already exists");
        require(relationshipImplementation!=address(0),"relationshipImplementation not set");
        // TODO: Verify otherAccountsignature with owner of the other NFT using owner() function of ERC6551
        address relationship = _deployProxy(relationshipImplementation, 1);
        require(relationshipExists[relationship] == false, "Relationship already exists");
        
        IRelationship(relationship).initialize(nft1, nft2);
        relationshipExists[relationship] = true;
        pairs[nft1.contractAddress][nft2.contractAddress]=true;
        pairs[nft2.contractAddress][nft1.contractAddress]=true;
        emit RelationshipCreated(nft1, nft2, relationship);

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
        address owner=IERC721URIStorage(nftAddress).ownerOf(tokenId);
        string memory tokenUri=IERC721URIStorage(nftAddress).tokenURI(tokenId);
        return IRelationship.NFT(tokenId,tokenUri,owner,nftAddress,chainId,chainSelector);
    }

    function isRelationship(address _address) external view returns (bool) {
        return relationshipExists[_address];
    }
      function supportsInterface(bytes4 interfaceId) public pure override(CCIPReceiver) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
 
}