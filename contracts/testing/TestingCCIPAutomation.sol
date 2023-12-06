// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/ILogAutomation.sol";
import "../interfaces/IRelationship.sol";
contract TestingCCIPAutomation is ILogAutomation {

   enum PayFeesIn {
        Native,
        LINK
    }

    address public immutable i_router;
    address public immutable i_link;
    address public zexCraftNftContract;
    uint256 public mintFee ;
    address public baseChainAddress;
    address public ccipToken;
    uint64 public destinationChainSelector;

    mapping(address=>uint256) public depositBalances;

  

    constructor(address router, address link, address _zexCraftNftContract,address _baseChainAddress,uint256 _mintFee,address _ccipToken, uint64 _destinationChainSelector) {
        i_router = router;
        i_link = link;
        LinkTokenInterface(i_link).approve(i_router, type(uint256).max);

        zexCraftNftContract = _zexCraftNftContract;
        mintFee = _mintFee;
        ccipToken = _ccipToken;
        baseChainAddress = _baseChainAddress;
        destinationChainSelector=_destinationChainSelector;
    }

    event MessageSent(bytes32 messageId);
    event LogTriggerUpkeepData(uint256 requestId,bytes data);
    event ZexCraftNftRequested(uint256 requestId);
    event LinkDeposited(address sender,uint256 currentDeposit,uint256 totalDeposit);
  


    function depositLink(uint amount) public {
        require(LinkTokenInterface(i_link).allowance(msg.sender, address(this))>=amount, "Unable to transfer");
        LinkTokenInterface(i_link).transferFrom(msg.sender, address(this), amount);
        depositBalances[msg.sender] += amount;
        emit LinkDeposited(msg.sender,amount,depositBalances[msg.sender]);
    }

    // test log trigger automation
    // test ccip
    function createCrossChainMint(string memory prompt, PayFeesIn payFeesIn) public payable{
        require(IERC20(ccipToken).allowance(msg.sender,address(this))>=mintFee,"Approve tokens first");
       
        (Client.EVM2AnyMessage memory message,uint256 fee)=getCreateCrosschainMint(  prompt,  payFeesIn);

        bytes32 messageId;

        if (payFeesIn == PayFeesIn.LINK) {
            require(depositBalances[msg.sender]>=fee,"Insufficient LINK balance");
            depositBalances[msg.sender] -= fee;
            LinkTokenInterface(i_link).approve(i_router, fee);
            messageId = IRouterClient(i_router).ccipSend(
                destinationChainSelector,
                message
            );
        } else {
            require(msg.value>=fee,"Insufficient ETH balance");
            messageId = IRouterClient(i_router).ccipSend{value: fee}(
                destinationChainSelector,
                message
            );
        }
        emit MessageSent(messageId);
    }

    function createCrosschainRelationship(address partnerAccount,uint256 partnerChainid, PayFeesIn payFeesIn, bytes memory partnerSig) public payable{

        bytes32 messageId;
        (Client.EVM2AnyMessage memory message,uint256 fee)=getCrosschainRelationshipMessage(payFeesIn);

        if (payFeesIn == PayFeesIn.LINK) {
            require(depositBalances[msg.sender]>=fee,"Insufficient LINK balance");
            depositBalances[msg.sender] -= fee;
            LinkTokenInterface(i_link).approve(i_router, fee);
            messageId = IRouterClient(i_router).ccipSend(
                destinationChainSelector,
                message
            );
        } else {
            require(msg.value>=fee,"Insufficient ETH balance");
            messageId = IRouterClient(i_router).ccipSend{value: fee}(
                destinationChainSelector,
                message
            );
        }

        emit MessageSent(messageId);
    }

    function createCrosschainBaby(address relationship,bytes memory partnerSig,PayFeesIn payFeesIn) public payable{
    
      (Client.EVM2AnyMessage memory message ,uint256 fee) =getCreateBabyZexCraftNft(relationship,partnerSig,payFeesIn);

        bytes32 messageId;
        if (payFeesIn == PayFeesIn.LINK) {
            require(depositBalances[msg.sender]>=fee,"Insufficient LINK balance");
            depositBalances[msg.sender] -= fee;
            LinkTokenInterface(i_link).approve(i_router, fee);
            messageId = IRouterClient(i_router).ccipSend(
                destinationChainSelector,
                message
            );
        } else {
            require(msg.value>=fee,"Insufficient ETH balance");
            messageId = IRouterClient(i_router).ccipSend{value: fee}(
                destinationChainSelector,
                message
            );
        }

        emit MessageSent(messageId);

    }

    function triggerLogAutomation(uint requestId) public 
    {
        emit ZexCraftNftRequested(requestId);
    }


   function checkLog(
        Log calldata log,
        bytes memory
    ) external pure returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = true;
        performData = log.data;
    }
    
    function performUpkeep(bytes calldata performData) external override {
      uint256 _requestId = abi.decode(performData, (uint256));

      emit LogTriggerUpkeepData(_requestId,performData);
    }

    function getCrosschainRelationshipMessage(PayFeesIn payFessIn) public view returns(Client.EVM2AnyMessage memory,uint256)
    {
        IRelationship.NFT memory nft1;
   
        nft1=IRelationship.NFT({
            tokenId: 79,
            tokenURI: "Avalanche is Awesome",
            ownerDuringMint: 0x0429A2Da7884CA14E53142988D5845952fE4DF6a,
            contractAddress: address(0),
            chainId: 5,
            sourceChainSelector: 16015286601757825753
        });
    
        IRelationship.NFT memory nft2=IRelationship.NFT({
            tokenId: 420,
            tokenURI: "Chainlink is Awesome",
            ownerDuringMint: 0x3Ee9106fe2315bAe14e95ec969F2c9E54a9AbbD7,
            contractAddress: 0x7605D4F91E3BE79CC99Dd7c12C04CDb0BDB8d301,
            chainId: 20,
            sourceChainSelector: 2664363617261496610
        });
        bytes memory partnerSig=abi.encode(nft1,nft2);

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(baseChainAddress),
            data: abi.encode(nft1,nft2,partnerSig),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: payFessIn == PayFeesIn.LINK ? i_link : address(0)
        });

        uint256 fee = IRouterClient(i_router).getFee(
            destinationChainSelector,
            message
        );  

        return (message,fee);
    }


       function getCreateCrosschainMint(string memory prompt, PayFeesIn payFeesIn) public view returns(Client.EVM2AnyMessage memory message,uint256 fee)
    {
        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({token: ccipToken, amount: mintFee});
         message = Client.EVM2AnyMessage({
            receiver: abi.encode(baseChainAddress),
            data: abi.encode(msg.sender,prompt,zexCraftNftContract),
            tokenAmounts: tokenAmounts,
            extraArgs: "",
            feeToken: payFeesIn == PayFeesIn.LINK ? i_link : address(0)
        });

         fee = IRouterClient(i_router).getFee(
            destinationChainSelector,
            message
        );
    }

    function getCreateBabyZexCraftNft(address relationship, bytes memory partnerSig,PayFeesIn payFeesIn ) public view returns(Client.EVM2AnyMessage memory message,uint fee)
  {  
      message = Client.EVM2AnyMessage({
            receiver: abi.encode(baseChainAddress),
            data: abi.encode(relationship,partnerSig),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: payFeesIn == PayFeesIn.LINK ? i_link : address(0)
        });

         fee = IRouterClient(i_router).getFee(
            destinationChainSelector,
            message
        );

  }
}