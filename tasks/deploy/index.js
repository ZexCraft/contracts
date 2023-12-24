exports.deployInCraft = require("../deploy/deployInCraft.js")
exports.deployImplementation = require("../deploy/deployErc6551Implementation.js")
exports.deployRegistry = require("../deploy/deployErc6551Registry.js")
exports.deployPowerups = require("./deployPowerups.js")
exports.deployRelationship = require("./deployRelationshipImplementation.js")
exports.deployRelationshipRegistry = require("./deployRelationshipRegistry.js")
exports.deployCraftToken = require("./deployCraftToken.js")
exports.deployTestNFT = require("./deployTestNFT.js")

/* Deploy order 

1. ERC6551 Implementation - npx hardhat deploy-implementation --network inEvmTestnet --verify true
2. ERC6551 Registry - npx hardhat deploy-registry --network inEvmTestnet --verify true
3. Relationship Implementation - npx hardhat deploy-relationship --network inEvmTestnet --verify true
4. Relationship Registry - npx hardhat deploy-relationship-registry --network inEvmTestnet --verify true
5. InCraft - npx hardhat deploy-incraft --network inEvmTestnet --verify true
6. CraftToken - npx hardhat deploy-craft-token --network inEvmTestnet --verify true

Call setCraftToken in InCraft
Call initialize in RelRegistry

*/
