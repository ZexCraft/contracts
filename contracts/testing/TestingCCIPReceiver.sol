// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";

import "../interfaces/IRelationship.sol";


contract TestingCCIPReceiver is CCIPReceiver, ConfirmedOwner{

  // Chainlink CCIP Variables
  uint public crosschainMintFee;
  bytes32 public s_lastReceivedMessageId;
  bytes public  s_lastReceivedData ;
  address public router;
  mapping(uint64 => mapping(address => bool)) public allowlistedAddresses;  

  bool public s_receive;


  constructor(address _router,uint256 _crosschainMintFee) CCIPReceiver(_router) ConfirmedOwner(msg.sender) {
      router = _router;
      crosschainMintFee=_crosschainMintFee;
      s_receive=false;
    }

  event MessageReceived(bytes32 messageId, bytes data);
  event OperationFailed();
  event CrosschainMintReceived(address creator,string prompt,address zexCraftContract);
  event CrosshchainRelationshipReceived(IRelationship.NFT nft1,IRelationship.NFT nft2,bytes partnerSig);
  event CrosschainCreateBabyReceived(address sender, bytes signature);

  modifier onlyAllowlisted(uint64 sourceChainSelector,address sender)
  {
    require(allowlistedAddresses[sourceChainSelector][sender]==true,"not allowlisted");
    _;
  }

  function setReceive(bool _receive) external onlyOwner {
    s_receive = _receive;
  }


  function addZexCraftMintCrossChain(uint64[] memory sourceChainSelector,address[] memory sender) external onlyOwner {
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
         if(any2EvmMessage.destTokenAmounts.length != 0&& any2EvmMessage.destTokenAmounts[0].amount>=crosschainMintFee){
            (address creator,string memory prompt, address zexCraftContract)=abi.decode(any2EvmMessage.data, (address,string,address));
            emit CrosschainMintReceived(creator, prompt, zexCraftContract);
          }
          else{
            if(s_receive)
            {
                (address sender,bytes memory signature)=abi.decode(any2EvmMessage.data, (address,bytes));

                emit CrosschainCreateBabyReceived(sender,signature);
            }else{
                 (IRelationship.NFT memory nft1,IRelationship.NFT memory nft2,bytes memory partnerSig)=abi.decode(any2EvmMessage.data, (IRelationship.NFT,IRelationship.NFT,bytes));
 
              emit CrosshchainRelationshipReceived(nft1,nft2,partnerSig);
            }
          }
        emit MessageReceived(any2EvmMessage.messageId, any2EvmMessage.data);
    }
 



}
