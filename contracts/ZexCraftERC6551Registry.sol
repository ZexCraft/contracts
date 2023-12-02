// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./interfaces/IERC6551Registry.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

contract ZexCraftERC6551Registry is IERC6551Registry {

  error InitializationFailed();
  address immutable i_implementation;
  
  mapping(address => bool) public accountExists;

  constructor(address implementation) {
    i_implementation = implementation;
  }




  function createAccount(
    address implementation,
    uint256 chainId,
    address tokenContract,
    uint256 tokenId,
    uint256 salt,
    bytes memory initData
  ) external payable returns (address) {
    return _createAccount(implementation, chainId, tokenContract, tokenId);
   
  }


  function createAccountAndCall(
    address implementation,
    uint256 chainId,
    address tokenContract,
    uint256 tokenId,
    uint256 salt,
    bytes memory initData,
    address crossChainContract
  ) external payable returns (address) {
  address accountAddress=_createAccount(implementation, chainId, tokenContract, tokenId);
  (bool success,)=crossChainContract.call{value: msg.value}(abi.encodeWithSignature("createCrosschainImport(address,uint256,address,address,uint8)", tokenContract,tokenId,msg.sender,accountAddress,0));
  require(success,"Failed to create crosschain import");

  return accountAddress;
  }



  function _createAccount(
    address implementation,
    uint256 chainId,
    address tokenContract,
    uint256 tokenId
  ) internal returns (address) {
     require(implementation == i_implementation, "Invalid implementation");
    require(msg.sender == IERC721(tokenContract).ownerOf(tokenId), "Invalid owner");
    bytes memory code = _creationCode(implementation, chainId, tokenContract, tokenId, 1);
    address account_ = Create2.computeAddress(bytes32(uint256(1)), keccak256(code));

    if (account_.code.length != 0) return account_;

    account_ = Create2.deploy(0, bytes32(uint256(1)), code);

  
    emit AccountCreated(account_, implementation, chainId, tokenContract, tokenId, uint256(1));
    return account_;
  }

  
  function account(
    address implementation,
    uint256 chainId,
    address tokenContract,
    uint256 tokenId,
    uint256 salt
  ) external view returns (address) {
    return _account(implementation, chainId, tokenContract, tokenId );
  }

  function _account(
    address implementation,
    uint256 chainId,
    address tokenContract,
    uint256 tokenId
  ) internal view returns (address) {
    bytes32 bytecodeHash = keccak256(_creationCode(implementation, chainId, tokenContract, tokenId, uint256(1)));

    return Create2.computeAddress(bytes32(uint256(1)), bytecodeHash);
  }

  function _creationCode(
    address implementation_,
    uint256 chainId_,
    address tokenContract_,
    uint256 tokenId_,
    uint256 salt_
  ) internal pure returns (bytes memory) {
    return
      abi.encodePacked(
        hex"3d60ad80600a3d3981f3363d3d373d3d3d363d73",
        implementation_,
        hex"5af43d82803e903d91602b57fd5bf3",
        abi.encode(salt_, chainId_, tokenContract_, tokenId_)
      );
  }

  function isAccount(address accountAddress) external view override returns (bool) {
    return accountExists[accountAddress];
  }
}
