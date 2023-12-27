exports.deployZexCraft = require("../deploy/deployZexCraft.js")
exports.deployImplementation = require("../deploy/deployErc6551Implementation.js")
exports.deployRegistry = require("../deploy/deployErc6551Registry.js")
exports.deployPowerups = require("./deployPowerups.js")
exports.deployRelationship = require("./deployRelationshipImplementation.js")
exports.deployRelationshipRegistry = require("./deployRelationshipRegistry.js")
exports.deployCraftToken = require("./deployCraftToken.js")
exports.deployTestNFT = require("./deployTestNFT.js")

/* Deploy order 

1. ERC6551 Implementation - npx hardhat deploy-implementation --network victionTestnet --verify true
2. ERC6551 Registry - npx hardhat deploy-registry --network victionTestnet --verify true
3. Relationship Implementation - npx hardhat deploy-relationship --network victionTestnet --verify true
4. Relationship Registry - npx hardhat deploy-relationship-registry --network victionTestnet --verify true
5. ZexCraft - npx hardhat deploy-zexcraft --network victionTestnet --verify true
6. CraftToken - npx hardhat deploy-craft-token --network victionTestnet --verify true

Call setCraftToken in ZexCraft
Call initialize in RelRegistry

*/
