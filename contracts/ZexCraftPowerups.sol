// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract ZexCraftPowerups{

    struct Powerup{
        string name;
        string power;
        uint256 priceInUSD;
    }
    uint public powerupCounter;
    mapping(uint=>Powerup) public powerups;
    mapping(address=>mapping(uint=>uint))public powerupBalances;
    AggregatorV3Interface public priceFeed;

    address public owner;
    constructor(Powerup[] memory _powerups)
    {
        owner=msg.sender;
        _addPowerups(_powerups);
        priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
    }


    event PowerupCreated(uint256 powerupId,string name,string power,uint256 priceInUSD);
    event PurchasedPowerup(address indexed buyer,uint256 powerupId,uint256 amount);

    function addPowerup(string memory name, string memory _powerup,uint256 priceInUSD) public
    {
        Powerup[] memory powerup;
        powerup[0]=Powerup(name,_powerup,priceInUSD);
        _addPowerups(powerup);
    }
    
    function addPowerups(Powerup[] memory _powerups) public
    {
        _addPowerups(_powerups);
    }   

    function _addPowerups(Powerup[] memory _powerups) internal
    {    
        for(uint i=0;i<_powerups.length;i++)
        {
            powerupCounter++;
            powerups[powerupCounter]=_powerups[i];
            emit PowerupCreated(powerupCounter,_powerups[i].name,_powerups[i].power,_powerups[i].priceInUSD);
        }
    }



    function purchasePowerup(uint256 powerupId)external payable {
        uint256 priceInAvax=getLatestUSDToAVAX();
        uint256 price=powerups[powerupId].priceInUSD*priceInAvax;
        require(msg.value>=price,"Not enough AVAX");

        powerupBalances[msg.sender][powerupId]+=msg.value/price;

        emit PurchasedPowerup(msg.sender,powerupId,msg.value/price);
    }


    function getLatestUSDToAVAX() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }


    function claimFunds() public  {
        require(msg.sender==owner,"Not owner");
        payable(owner).transfer(address(this).balance);
    }
}