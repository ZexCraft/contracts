// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IERC6551Registry.sol";


contract ZexCraftCrosschainMint{

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
   
    mapping(address=>uint256) public depositBalances;

    uint64 public destinationChainSelector = 14767482510784806043;


    constructor(address router, address link, address _zexCraftNftContract,address _baseChainAddress,uint256 _mintFee,address _ccipToken) {
        i_router = router;
        i_link = link;
        LinkTokenInterface(i_link).approve(i_router, type(uint256).max);

        zexCraftNftContract = _zexCraftNftContract;
        mintFee = _mintFee;
        ccipToken = _ccipToken;
        baseChainAddress = _baseChainAddress;
    }

    event MessageSent(bytes32 messageId);

      event LinkDeposited(address sender,uint256 currentDeposit,uint256 totalDeposit);
  


    function depositLink(uint amount) public {
        require(LinkTokenInterface(i_link).allowance(msg.sender, address(this))>=amount, "Unable to transfer");
        LinkTokenInterface(i_link).transferFrom(msg.sender, address(this), amount);
        depositBalances[msg.sender] += amount;
        emit LinkDeposited(msg.sender,amount,depositBalances[msg.sender]);
    }

    function createCrosschain(string memory prompt, PayFeesIn payFeesIn) public payable{
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

}



