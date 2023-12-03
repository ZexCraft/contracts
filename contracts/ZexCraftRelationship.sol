// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IRelationship.sol";
import "./interfaces/IZexCraftNFT.sol";

contract ZexCraftRelationship{
    uint256 public state;

    IRelationship.NFT[2] public nfts;

    address public zexCraftAddress;

    function intialize(IRelationship.NFT memory nft1,IRelationship.NFT memory nft2,address _zexCraftAddress) external
    {
       nfts[0]=nft1;
       nfts[1]=nft2;
       zexCraftAddress=_zexCraftAddress;
    }


   function execute(
    address to,
    uint256 value,
    bytes calldata data,
    uint8 operation,
    bytes[2] memory signatures
  ) external payable virtual returns (bytes memory result) {
    // TODO: Check if both the signatures are valid
    require(msg.sender==nfts[0].ownerDuringMint||msg.sender==nfts[1].ownerDuringMint,"Invalid sender");
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


  function createBaby() external {
    require(msg.sender==nfts[0].ownerDuringMint||msg.sender==nfts[1].ownerDuringMint,"Invalid sender");
    IZexCraftNFT(zexCraftAddress).createBabyZexCraftNft(nfts[0],nfts[1]);
  }

}