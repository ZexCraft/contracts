// const { expect } = require("chai")
// const { ethers } = require("hardhat")

// describe("create-baby", function () {
//   let ERC6865Registry
//   let registry
//   let owner
//   let notOwnerAddress
//   let implementationAddress

//   beforeEach(async function () {
//     ERC6865Registry = await ethers.getContractFactory("ERC6865Registry")
//     ;[owner, notOwnerAddress] = await ethers.getSigners()
//     implementationAddress = ethers.Wallet.createRandom().address
//     registry = await ERC6865Registry.deploy()
//     await registry.deployed()
//   })

//   it("Should add and get implementation", async function () {
//     const domainSeparator = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("test"))

//     // Add implementation
//     await registry.connect(owner).addImplementation(domainSeparator, implementationAddress)

//     // Get implementation
//     const result = await registry.getImplementation(domainSeparator)

//     expect(result).to.equal(implementationAddress)
//   })

//   it("Should fail to add implementation from non-owner", async function () {
//     const domainSeparator = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("test"))

//     // Try to add implementation from non-owner
//     await expect(
//       registry.connect(notOwnerAddress).addImplementation(domainSeparator, implementationAddress)
//     ).to.be.revertedWith("Ownable: caller is not the owner")
//   })

//   it("Should fail to add implementation with zero address", async function () {
//     const domainSeparator = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("test"))
//     const zeroAddress = ethers.constants.AddressZero

//     // Try to add implementation with zero address
//     await expect(registry.connect(owner).addImplementation(domainSeparator, zeroAddress)).to.be.revertedWith(
//       "Invalid implementation address"
//     )
//   })
// })
