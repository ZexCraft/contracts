// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

import "../interfaces/IERC6551Account.sol";
import "../interfaces/IRelationship.sol";
import "../interfaces/IERC6551Registry.sol";
import "../interfaces/IERC721.sol";

interface IERC6551Executable {
  function execute(
    address to,
    uint256 value,
    bytes calldata data,
    uint8 operation
  ) external payable returns (bytes memory);
}

contract ZexCraftERC6551AccountCrossChain is IERC165, IERC1271, IERC6551Account, IERC6551Executable {
    enum PayFeesIn {
        Native,
        LINK
    }
  uint256 public state;
    
    address public immutable i_router;
    address public immutable i_link;
    address public zexCraftRelationshipRegistry;
    uint256 public mintFee ;
    bool public isInitialized;
    address public ccipToken;
    mapping(address=>uint256) public depositBalances;
    IERC6551Registry public accountRegistry;

    uint64 public destinationChainSelector = 14767482510784806043;
    uint64 public sourceChainSelector;
    address public authorized;

    constructor(address router, address link, address _zexCraftRelationshipRegistry,address _ccipToken, uint64 _sourceChainSelector) {
        i_router = router;
        i_link = link;
        LinkTokenInterface(i_link).approve(i_router, type(uint256).max);

        zexCraftRelationshipRegistry = _zexCraftRelationshipRegistry;
        ccipToken = _ccipToken;
        sourceChainSelector = _sourceChainSelector;
        authorized=msg.sender;
    }


    receive() external payable {}

    modifier onlyOnce(){
        require(!isInitialized,"Not authorized");
        _;
    }

    function initialize(address _accountRegistry) external onlyOnce {
        accountRegistry = IERC6551Registry(_accountRegistry);
        isInitialized=true;
    }
    event MessageSent(bytes32 messageId);

      event LinkDeposited(address sender,uint256 currentDeposit,uint256 totalDeposit);
  


    function depositLink(uint amount) public {
        require(LinkTokenInterface(i_link).allowance(msg.sender, address(this))>=amount, "Unable to transfer");
        LinkTokenInterface(i_link).transferFrom(msg.sender, address(this), amount);
        depositBalances[msg.sender] += amount;
        emit LinkDeposited(msg.sender,amount,depositBalances[msg.sender]);
    }



  function createRelationship(address partnerAccount,uint256 partnerChainid, PayFeesIn payFeesIn, bytes memory partnerSig) public payable{
    // TODO: Verify partner Signature 
    require(_isValidSigner(msg.sender), "Invalid signer");
    
        (Client.EVM2AnyMessage memory message,uint256 fee)=getCreateRelationship(partnerAccount,partnerChainid,payFeesIn,partnerSig);
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

  function getCreateRelationship(address partnerAccount,uint256 partnerChainid, PayFeesIn payFeesIn, bytes memory partnerSig) public view returns(Client.EVM2AnyMessage memory message, uint fee)
  {
      IRelationship.NFT memory nft1;
      if(partnerChainid==block.chainid)
      {
        nft1=_getNft(partnerAccount);
      }else if(partnerChainid==43113 ){
        nft1=IRelationship.NFT({
            tokenId: 0,
            tokenURI: "",
            ownerDuringMint: partnerAccount,
            contractAddress: address(0),
            chainId: partnerChainid,
            sourceChainSelector: destinationChainSelector
        });
      }else{
        revert("Invalid chainId");
      }
    
      IRelationship.NFT memory nft2=_getNft(msg.sender);
      message = Client.EVM2AnyMessage({
            receiver: abi.encode(zexCraftRelationshipRegistry),
            data: abi.encode(nft1,nft2,partnerSig),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: payFeesIn == PayFeesIn.LINK ? i_link : address(0)
        });

        fee = IRouterClient(i_router).getFee(
            destinationChainSelector,
            message
        );

  }


  function createBabyZexCraftNft(address relationship, bytes memory partnerSig,PayFeesIn payFeesIn) public payable{
    require(_isValidSigner(msg.sender),"Invalid signer");
    
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
  
  function getCreateBabyZexCraftNft(address relationship, bytes memory partnerSig,PayFeesIn payFeesIn ) public view returns(Client.EVM2AnyMessage memory message,uint fee)
  {  
      message = Client.EVM2AnyMessage({
            receiver: abi.encode(zexCraftRelationshipRegistry),
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
  function execute(
    address to,
    uint256 value,
    bytes memory data,
    uint8 operation
  ) external payable virtual returns (bytes memory result) {
    require(_isValidSigner(msg.sender), "Invalid signer");

    return _execute(to, value, data, operation);
  }


  function _execute(
    address to,
    uint256 value,
    bytes memory data,
    uint8 operation
  ) internal virtual returns (bytes memory result) {
    ++state;

    bool success;
    (success, result) = to.call{value: value}(data);

    if (!success) {
      assembly {
        revert(add(result, 32), mload(result))
      }
    }
  }

  function isValidSigner(address signer, bytes calldata) external view virtual returns (bytes4) {
    if (_isValidSigner(signer)) {
      return IERC6551Account.isValidSigner.selector;
    }

    return bytes4(0);
  }

  function isValidSignature(bytes32 hash, bytes memory signature) external view virtual returns (bytes4 magicValue) {
    bool isValid = SignatureChecker.isValidSignatureNow(owner(), hash, signature);

    if (isValid) {
      return IERC1271.isValidSignature.selector;
    }

    return bytes4(0);
  }

  function supportsInterface(bytes4 interfaceId) external pure virtual returns (bool) {
    return
      interfaceId == type(IERC165).interfaceId ||
      interfaceId == type(IERC6551Account).interfaceId ||
      interfaceId == type(IERC6551Executable).interfaceId;
  }

  function token() public view virtual returns (uint256, address, uint256) {
    bytes memory footer = new bytes(0x60);

    assembly {
      extcodecopy(address(), add(footer, 0x20), 0x4d, 0x60)
    }

    return abi.decode(footer, (uint256, address, uint256));
  }

  function owner() public view virtual returns (address) {
    (uint256 chainId, address tokenContract, uint256 tokenId) = token();
    if (chainId != block.chainid) return address(0);

    return IERC721(tokenContract).ownerOf(tokenId);
  }

  function _isValidSigner(address signer) internal view virtual returns (bool) {
    return signer == owner();
  }

    function _getNft(address account) internal view returns (IRelationship.NFT memory) {
        if(accountRegistry!=IERC6551Registry(address(0)))
        require(accountRegistry.isAccount(account), "Invalid account");
        (uint256 chainId, address nftAddress, uint256 tokenId)=IERC6551Account(payable(account)).token();
        address _owner=IERC721(nftAddress).ownerOf(tokenId);
        string memory tokenUri=IERC721(nftAddress).tokenURI(tokenId);
        return IRelationship.NFT(tokenId,tokenUri,_owner,nftAddress,chainId,sourceChainSelector );
    }


     function isSigner(address signer) external view returns (bool) {
        return _isValidSigner(signer);
     }
}
