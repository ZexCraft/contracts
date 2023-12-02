// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

contract ZexCraftCrosschainMint{

    enum PayFeesIn {
        Native,
        LINK
    }

    enum Status{
        DOES_NOT_EXIST,
        REQUESTED,
        MINTED 
    }

    address immutable i_router;
    address immutable i_link;
    address public zexCraftNftContract;

    event MessageSent(bytes32 messageId);

    constructor(address router, address link, address _zexCraftNftContract) {
        i_router = router;
        i_link = link;
        LinkTokenInterface(i_link).approve(i_router, type(uint256).max);
        zexCraftNftContract = _zexCraftNftContract;
    }


    struct NewZexCraftNftRequest {
        string prompt;
        uint256 requestId;
        address creator;
        Status status;
    }


    receive() external payable {}


    function depositLink(uint amount) public {
        require(LinkTokenInterface(i_link).allowance(msg.sender, address(this))>=amount, "Unable to transfer");
        LinkTokenInterface(i_link).transferFrom(msg.sender, address(this), amount);
    }

    function createCrosschainMint(string memory prompt, uint64 destinationChainSelector, PayFeesIn payFeesIn) public {
         Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(zexCraftNftContract),
            data: abi.encodeWithSignature("createNewZexCraftNft(string)", prompt),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: payFeesIn == PayFeesIn.LINK ? i_link : address(0)
        });

        uint256 fee = IRouterClient(i_router).getFee(
            destinationChainSelector,
            message
        );

        bytes32 messageId;

        if (payFeesIn == PayFeesIn.LINK) {
            LinkTokenInterface(i_link).approve(i_router, fee);
            messageId = IRouterClient(i_router).ccipSend(
                destinationChainSelector,
                message
            );
        } else {
            messageId = IRouterClient(i_router).ccipSend{value: fee}(
                destinationChainSelector,
                message
            );
        }

        emit MessageSent(messageId);
        
    }





    
    


}