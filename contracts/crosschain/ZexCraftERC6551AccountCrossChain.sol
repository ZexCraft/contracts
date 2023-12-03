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
    address public ccipToken;
    mapping(address=>uint256) public depositBalances;
    IERC6551Registry public accountRegistry;

    uint64 public destinationChainSelector = 14767482510784806043;
    address public authorized;

    constructor(address router, address link, address _zexCraftRelationshipRegistry,address _ccipToken) {
        i_router = router;
        i_link = link;
        LinkTokenInterface(i_link).approve(i_router, type(uint256).max);

        zexCraftRelationshipRegistry = _zexCraftRelationshipRegistry;
        ccipToken = _ccipToken;
        authorized=msg.sender;
    }

    event MessageSent(bytes32 messageId);

    receive() external payable {}

    function setAccountRegistry(IERC6551Registry _accountRegistry) public 
    {
        require(msg.sender==authorized,"Not authorized");
        accountRegistry=_accountRegistry;
    }
 

    function depositLink(uint amount) public {
        require(LinkTokenInterface(i_link).allowance(msg.sender, address(this))>=amount, "Unable to transfer");
        LinkTokenInterface(i_link).transferFrom(msg.sender, address(this), amount);
        depositBalances[msg.sender] += amount;
    }

  function getCreateRelationshipData(address otherAccount,bytes[2] memory signatures)public pure returns(bytes memory)
  {
    return abi.encodeWithSignature("createRelationship(address,bytes[2])",otherAccount,signatures);
  }

//   function createRelationship(address relationshipRegistry,address otherAccount,bytes[2] memory signatures) external returns (address) {
//     return abi.decode(_execute(relationshipRegistry, 0, getCreateRelationshipData(otherAccount,signatures), 0), (address));
//   }
 


function createRelationship(address partnerAccount,uint256 chainId, PayFeesIn payFeesIn, bytes memory partnerSig) public payable{
    // TODO: Verify partner Signature too
    require(_isValidSigner(msg.sender), "Invalid signer");
    IRelationship.NFT memory nft1;
    if(chainId==block.chainid)
    {
        nft1=_getNft(partnerAccount);
    }else if(chainId==43113 ){
        nft1=IRelationship.NFT({
            tokenId: 0,
            tokenURI: "",
            ownerDuringMint: partnerAccount,
            contractAddress: address(0),
            chainId: chainId
        });
    }else{
        revert("Invalid chainId");
    }
    
    IRelationship.NFT memory nft2=_getNft(msg.sender);
    Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(zexCraftRelationshipRegistry),
            data: abi.encode(nft1,nft2),
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
        return IRelationship.NFT(tokenId,tokenUri,_owner,nftAddress,chainId);
    }
}
