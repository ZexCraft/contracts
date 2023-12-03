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
    address public ccipToken;
    
    mapping(address=>uint256) public depoistBalances;

    uint64 public destinationChainSelector = 14767482510784806043;

    address public baseChainAddress;

    event MessageSent(bytes32 messageId);

    constructor(address router, address link, address _zexCraftNftContract,address _baseChainAddress,uint256 _mintFee,address _ccipToken) {
        i_router = router;
        i_link = link;
        LinkTokenInterface(i_link).approve(i_router, type(uint256).max);

        zexCraftNftContract = _zexCraftNftContract;
        mintFee = _mintFee;
        ccipToken = _ccipToken;
        baseChainAddress = _baseChainAddress;
    }

    receive() external payable {}

    function depositLink(uint amount) public {
        require(LinkTokenInterface(i_link).allowance(msg.sender, address(this))>=amount, "Unable to transfer");
        LinkTokenInterface(i_link).transferFrom(msg.sender, address(this), amount);
        depoistBalances[msg.sender] += amount;
    }

    function createCrosschain(string memory prompt, PayFeesIn payFeesIn) public payable{
        require(IERC20(ccipToken).allowance(msg.sender,address(this))>=mintFee,"Approve tokens first");
        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({token: ccipToken, amount: mintFee});
         Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(baseChainAddress),
            data: abi.encode(msg.sender,prompt,zexCraftNftContract),
            tokenAmounts: tokenAmounts,
            extraArgs: "",
            feeToken: payFeesIn == PayFeesIn.LINK ? i_link : address(0)
        });

        uint256 fee = IRouterClient(i_router).getFee(
            destinationChainSelector,
            message
        );

        bytes32 messageId;

        if (payFeesIn == PayFeesIn.LINK) {
            require(depoistBalances[msg.sender]>=fee,"Insufficient LINK balance");
            depoistBalances[msg.sender] -= fee;
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

}



