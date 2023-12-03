// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";

import "./interfaces/IZexCraftNFT.sol";

contract ZexCraftBaseChain is CCIPReceiver, ConfirmedOwner{

  // Chainlink CCIP Variables
  uint public crosschainMintFee;
  bytes32 public s_lastReceivedMessageId;
  bytes public  s_lastReceivedData ;
  address public router;
  mapping(uint64 => mapping(address => bool)) public allowlistedAddresses;


  constructor(address _router,uint256 _crosschainMintFee) CCIPReceiver(_router) ConfirmedOwner(msg.sender) {
      router = _router;
      crosschainMintFee=_crosschainMintFee;
    }

  event MessageReceived(bytes32 messageId, bytes data);
  event OperationFailed();

  modifier onlyAllowlisted(uint64 sourceChainSelector,address sender)
  {
    require(allowlistedAddresses[sourceChainSelector][sender]==true,"not allowlisted");
    _;
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
            IZexCraftNFT(zexCraftContract).createNewZexCraftNftCrossChain(creator,prompt);
          }
          else{
            emit OperationFailed();
          }

      s_lastReceivedData = any2EvmMessage.data;
      s_lastReceivedMessageId = any2EvmMessage.messageId;
      emit MessageReceived(any2EvmMessage.messageId, any2EvmMessage.data);
    }
 


}