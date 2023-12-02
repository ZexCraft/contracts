// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IRelationship.sol";



contract ZexCraftRelationship{
    uint256 public state;

    IRelationship.NFT[2] public nfts;


    event RelationshipCreated(IRelationship.NFT nft1,IRelationship.NFT nft2);

    function intialize(IRelationship.NFT memory nft1,IRelationship.NFT memory nft2) external
    {
       nfts[0]=nft1;
       nfts[1]=nft2;
       emit RelationshipCreated(nft1,nft2);
    }


   function execute(
    address to,
    uint256 value,
    bytes calldata data,
    uint8 operation,
    bytes[2] memory signatures
  ) external payable virtual returns (bytes memory result) {
    // TODO: Check if both the signatures are valid
    require(operation == 0, "Only call operations are supported");
    ++state;

    bool success;
    (success, result) = to.call{value: value}(data);

    if (!success) {
      assembly {
        revert(add(result, 32), mload(result))
      }
    }
  }


  function getCreateBabyData()public view returns(bytes memory)
  {
    return abi.encodeWithSignature("createBabyZexCraftNft((uint256,string,address,address,uint256),(uint256,string,address,address,uint256))",nfts[0],nfts[1]);
  }

}