const { expect } = require("chai")
const { ethers, network } = require("hardhat")
const { MINT_FEE } = require("../networks")
const { arrayify, solidityKeccak256 } = require("ethers/lib/utils")
const { constants } = require("ethers")

describe("incraft", function () {
  let incraft
  let owner
  let notOwner
  let accountImplementation
  let craftToken
  let registry
  let relationship
  let relRegistry

  beforeEach(async function () {
    let signers = await ethers.getSigners()
    owner = signers[0]
    notOwner = signers[1]
    let InCraftERC6551Account = await ethers.getContractFactory("InCraftERC6551Account")
    accountImplementation = await InCraftERC6551Account.deploy()
    await accountImplementation.deployed()
    console.log("\nAccount Implementation deployed")
    console.log(accountImplementation.address)

    let InCraftERC6551Registry = await ethers.getContractFactory("InCraftERC6551Registry")
    registry = await InCraftERC6551Registry.deploy(accountImplementation.address)
    await registry.deployed()
    console.log("\nAccount Registry deployed")
    console.log(registry.address)

    let RelationshipImplementation = await ethers.getContractFactory("InCraftRelationship")
    relationship = await RelationshipImplementation.deploy()
    await relationship.deployed()
    console.log("\nRelationship Implementation deployed")
    console.log(relationship.address)

    let InCraftRelationshipRegistry = await ethers.getContractFactory("InCraftRelationshipRegistry")
    relRegistry = await InCraftRelationshipRegistry.deploy(registry.address, relationship.address, MINT_FEE)
    await relRegistry.deployed()
    console.log("\nRelationship Registry deployed")
    console.log(relRegistry.address)

    let InCraftNFT = await ethers.getContractFactory("InCraftNFT")
    incraft = await InCraftNFT.deploy(relRegistry.address, registry.address, MINT_FEE)
    await incraft.deployed()
    console.log("\nInCraft deployed")
    console.log(incraft.address)

    let CraftToken = await ethers.getContractFactory("CraftToken")
    craftToken = await CraftToken.deploy(incraft.address)
    await craftToken.deployed()
    console.log("\nCraftToken deployed")
    console.log(craftToken.address)

    console.log("\nInitializing InCraft")
    const setCraftTokenTx = await incraft.setCraftToken(craftToken.address)
    console.log("Tx Hash: ", setCraftTokenTx.hash)
    await setCraftTokenTx.wait()
    console.log("InCraft initialized")
    console.log("\nInitializing Relationship Registry")
    const initializeTx = await relRegistry.initialize(incraft.address, craftToken.address)
    console.log("Tx Hash: ", initializeTx.hash)
    await initializeTx.wait()
    console.log("Relationship Registry initialized")

    console.log("\nMiniting CraftToken to Owner and NotOwner")
    const mintOwnerTx = await craftToken.mint(owner.address)
    console.log("Mint Owner Tx Hash: ", mintOwnerTx.hash)
    await mintOwnerTx.wait()
    const mintNotOwnerTx = await craftToken.mint(notOwner.address)
    console.log("Mint NotOwner Tx Hash: ", mintNotOwnerTx.hash)
    await mintNotOwnerTx.wait()
    console.log("CraftToken minted to Owner and NotOwner")
  })

  it("Should create nft successfully", async function () {
    console.log("Owner address: ", owner.address)
    console.log("NotOwner address: ", notOwner.address)
    const nonce = await craftToken.nonces(notOwner.address)
    const tokenIdCounter = await incraft.tokenIdCounter()
    const accountAddress = await registry.account(
      accountImplementation.address,
      network.config.chainId,
      incraft.address,
      tokenIdCounter,
      1
    )

    const tokenURI = "https://bafkreibufkhlr6kaq4mhb4tpczbwtzm7jx2q7nrnwed2ndk6klrv6da54u.ipfs.nftstorage.link/"
    console.log("\nNonce: ", nonce.toString())
    const permitTokenHash = arrayify(
      solidityKeccak256(
        ["address", "address", "uint256", "uint256", "uint256"],
        [notOwner.address, incraft.address, MINT_FEE, nonce.toString(), constants.MaxUint256]
      )
    )
    const permitTokenSignature = await notOwner.signMessage(permitTokenHash)

    console.log("\nToken Hash: ")
    console.log(permitTokenHash)
    console.log("Token Signature: ")
    console.log(permitTokenSignature)

    const INCRAFT_MINT = "INCRAFT_MINT"

    const mintTokenHash = arrayify(
      solidityKeccak256(["string", "string", "address"], [INCRAFT_MINT, tokenURI, notOwner.address])
    )

    const mintTokenSignature = await notOwner.signMessage(mintTokenHash)
    console.log("\nMint Token Hash: ")
    console.log(mintTokenHash)
    console.log("Mint Token Signature: ")
    console.log(mintTokenSignature)

    const createNftTx = await incraft.createNft(tokenURI, notOwner.address, permitTokenSignature, mintTokenSignature)
    const createNftReceipt = await createNftTx.wait()
    const rarity = await incraft.rarity(tokenIdCounter)

    console.log("\nCreate NFT Tx Hash: ", createNftTx.hash)

    createNftReceipt.events.forEach((event) => {
      if (event.event == "InCraftNFTCreated") {
        expect(event.args[0]).to.equal(tokenIdCounter)
        expect(event.args[1]).to.equal(tokenURI)
        expect(event.args[2]).to.equal(notOwner.address)
        expect(event.args[3]).to.equal(accountAddress)
        expect(event.args[4]).to.equal(rarity)
        expect(event.args[5]).to.equal(false)
      }
    })
  })
})
