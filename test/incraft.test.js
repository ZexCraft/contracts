const { expect } = require("chai")
const { ethers, network } = require("hardhat")
const { MINT_FEE } = require("../networks")
const { arrayify, solidityKeccak256 } = require("ethers/lib/utils")
const { constants } = require("ethers")

describe("zexcraft", function () {
  let zexcraft
  let owner
  let notOwner
  let accountImplementation
  let craftToken
  let registry
  let relationship
  let relRegistry

  async function createNft(tokenURI, creator) {
    const nonce = await craftToken.nonces(creator.address)
    const tokenIdCounter = await zexcraft.tokenIdCounter()
    const accountAddress = await registry.account(
      accountImplementation.address,
      network.config.chainId,
      zexcraft.address,
      tokenIdCounter,
      1
    )

    console.log("\nNonce: ", nonce.toString())
    const permitTokenHash = arrayify(
      solidityKeccak256(
        ["address", "address", "uint256", "uint256", "uint256"],
        [creator.address, zexcraft.address, MINT_FEE, nonce.toString(), constants.MaxUint256]
      )
    )
    const permitTokenSignature = await creator.signMessage(permitTokenHash)

    console.log("\nToken Hash: ")
    console.log(permitTokenHash)
    console.log("Token Signature: ")
    console.log(permitTokenSignature)

    const ZEXCRAFT_MINT = "ZEXCRAFT_MINT"

    const mintTokenHash = arrayify(
      solidityKeccak256(["string", "string", "address"], [ZEXCRAFT_MINT, tokenURI, creator.address])
    )

    const mintTokenSignature = await creator.signMessage(mintTokenHash)
    console.log("\nMint Token Hash: ")
    console.log(mintTokenHash)
    console.log("Mint Token Signature: ")
    console.log(mintTokenSignature)

    const createNftTx = await zexcraft.createNft(tokenURI, creator.address, permitTokenSignature, mintTokenSignature)
    const createNftReceipt = await createNftTx.wait()
    const rarity = await zexcraft.rarity(tokenIdCounter)

    console.log("\nCreate NFT Tx Hash: ", createNftTx.hash)

    createNftReceipt.events.forEach((event) => {
      if (event.event == "ZexCraftNFTCreated") {
        expect(event.args[0]).to.equal(tokenIdCounter)
        expect(event.args[1]).to.equal(tokenURI)
        expect(event.args[2]).to.equal(creator.address)
        expect(event.args[3]).to.equal(accountAddress)
        expect(event.args[4]).to.equal(rarity)
      }
    })
    return accountAddress
  }

  async function createRelationship(firstTokenUri, secondTokenUri, firstOwner, secondOwner) {
    // Create First NFT and Account
    const firstAccountAddress = await createNft(firstTokenUri, firstOwner)

    // Create Second NFT and Second Account
    const secondAccountAddress = await createNft(secondTokenUri, secondOwner)

    // Create First Account Create Relationship Signature

    const firstCreateRelationshipHash = arrayify(
      solidityKeccak256(
        ["string", "address", "address"],
        ["ZEXCRAFT_CREATE_RELATIONSHIP", secondAccountAddress, firstAccountAddress]
      )
    )

    const firstCreateRelationshipSignature = await firstOwner.signMessage(firstCreateRelationshipHash)

    console.log("\n Create Relationship Hash: ")
    console.log(firstCreateRelationshipHash)
    console.log("Create Relationship Signature: ")
    console.log(firstCreateRelationshipSignature)

    // Second Account Create Relationship Transaction

    let ZexCraftERC6551Account = await ethers.getContractFactory("ZexCraftERC6551Account")
    let ownerAccount = ZexCraftERC6551Account.attach(secondAccountAddress)

    const relationshipNonce = await relRegistry.nonce()
    const relationshipAddress = await relRegistry.account(relationshipNonce)

    const createRelationshipTx = await ownerAccount.createRelationship(
      relRegistry.address,
      firstAccountAddress,
      firstCreateRelationshipSignature
    )
    const createRelationshipReceipt = await createRelationshipTx.wait()

    createRelationshipReceipt.events.forEach((event) => {
      if (event.event == "RelationshipCreated") {
        expect(event.args[0]).to.equal(secondAccountAddress)
        expect(event.args[1]).to.equal(firstAccountAddress)
        expect(event.args[2]).to.equal(relationshipAddress)
      }
    })
    return relationshipAddress
  }

  beforeEach(async function () {
    let signers = await ethers.getSigners()
    owner = signers[0]
    notOwner = signers[1]

    console.log("Owner address: ", owner.address)
    console.log("NotOwner address: ", notOwner.address)

    let ZexCraftERC6551Account = await ethers.getContractFactory("ZexCraftERC6551Account")
    accountImplementation = await ZexCraftERC6551Account.deploy()
    await accountImplementation.deployed()
    console.log("\nAccount Implementation deployed")
    console.log(accountImplementation.address)

    let ZexCraftERC6551Registry = await ethers.getContractFactory("ZexCraftERC6551Registry")
    registry = await ZexCraftERC6551Registry.deploy(accountImplementation.address)
    await registry.deployed()
    console.log("\nAccount Registry deployed")
    console.log(registry.address)

    let RelationshipImplementation = await ethers.getContractFactory("ZexCraftRelationship")
    relationship = await RelationshipImplementation.deploy()
    await relationship.deployed()
    console.log("\nRelationship Implementation deployed")
    console.log(relationship.address)

    let ZexCraftRelationshipRegistry = await ethers.getContractFactory("ZexCraftRelationshipRegistry")
    relRegistry = await ZexCraftRelationshipRegistry.deploy(registry.address, relationship.address, MINT_FEE)
    await relRegistry.deployed()
    console.log("\nRelationship Registry deployed")
    console.log(relRegistry.address)

    let ZexCraftNFT = await ethers.getContractFactory("ZexCraftNFT")
    zexcraft = await ZexCraftNFT.deploy(relRegistry.address, registry.address, MINT_FEE)
    await zexcraft.deployed()
    console.log("\nZexCraft deployed")
    console.log(zexcraft.address)

    let CraftToken = await ethers.getContractFactory("CraftToken")
    craftToken = await CraftToken.deploy(zexcraft.address)
    await craftToken.deployed()
    console.log("\nCraftToken deployed")
    console.log(craftToken.address)

    console.log("\nInitializing ZexCraft")
    const setCraftTokenTx = await zexcraft.setCraftToken(craftToken.address)
    console.log("Tx Hash: ", setCraftTokenTx.hash)
    await setCraftTokenTx.wait()
    console.log("ZexCraft initialized")
    console.log("\nInitializing Relationship Registry")
    const initializeTx = await relRegistry.initialize(zexcraft.address, craftToken.address)
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
    const tokenURI = "https://bafkreibufkhlr6kaq4mhb4tpczbwtzm7jx2q7nrnwed2ndk6klrv6da54u.ipfs.nftstorage.link/"
    const createdAccountAddress = await createNft(tokenURI, owner)
    console.log("\nCreated Account Address: ", createdAccountAddress)
  })

  it("should create relationship successfully", async function () {
    const firstTokenUri = "https://bafkreibufkhlr6kaq4mhb4tpczbwtzm7jx2q7nrnwed2ndk6klrv6da54u.ipfs.nftstorage.link/"
    const firstOwner = notOwner
    const secondTokenUri = "https://bafkreib6msd3hg6gmbju6oofsoc2wbd7q4jd3kmqrsuwvdqo77hqedhple.ipfs.nftstorage.link/"
    const secondOwner = owner

    const relationship = await createRelationship(firstTokenUri, secondTokenUri, firstOwner, secondOwner)
    console.log("\nRelationship Address: ", relationship)
  })

  it("should create baby successfully", async function () {
    const firstTokenUri = "https://bafkreibufkhlr6kaq4mhb4tpczbwtzm7jx2q7nrnwed2ndk6klrv6da54u.ipfs.nftstorage.link/"
    const firstOwner = notOwner
    const secondTokenUri = "https://bafkreib6msd3hg6gmbju6oofsoc2wbd7q4jd3kmqrsuwvdqo77hqedhple.ipfs.nftstorage.link/"
    const secondOwner = owner

    const relationship = await createRelationship(firstTokenUri, secondTokenUri, firstOwner, secondOwner)
    console.log("\nRelationship Address: ", relationship)

    const Relationship = await ethers.getContractFactory("ZexCraftRelationship")
    const relationshipContract = Relationship.attach(relationship)

    const babyNonce = await relationshipContract.nonce()
    const ZEXCRAFT_BREED = "ZEXCRAFT_BREED"

    const createBabyHash = arrayify(
      solidityKeccak256(["string", "address", "uint256"], [ZEXCRAFT_BREED, relationship, babyNonce])
    )

    const firstAccountSignature = await firstOwner.signMessage(createBabyHash)
    const secondAccountSignature = await secondOwner.signMessage(createBabyHash)

    const babyTokenURI = "https://bafkreiclp2df4tumxxh6jjegewdxpmqsysrbkzmqrak5rkiuldyewu5cfe.ipfs.nftstorage.link/"

    const tokenIdCounter = await zexcraft.tokenIdCounter()
    const babyAccountAddress = await registry.account(
      accountImplementation.address,
      network.config.chainId,
      zexcraft.address,
      tokenIdCounter,
      1
    )

    const dripTokensTx = await craftToken.mint(relationship)
    await dripTokensTx.wait()

    const createBabyTx = await relationshipContract.createBaby(babyTokenURI, [
      secondAccountSignature,
      firstAccountSignature,
    ])

    const createBabyReceipt = await createBabyTx.wait()
    const rarity = await zexcraft.rarity(tokenIdCounter)
    createBabyReceipt.events.forEach((event) => {
      if (event.event == "ZexCraftNFTBred") {
        expect(event.args[0]).to.equal(tokenIdCounter)
        expect(event.args[1]).to.equal(babyTokenURI)
        expect(event.args[2]).to.equal(relationship)
        expect(event.args[3]).to.equal(zexcraft.address)
        expect(event.args[4]).to.equal(zexcraft.address)
        expect(event.args[5]).to.equal(babyAccountAddress)
        expect(event.args[6]).to.equal(rarity)
      }
    })
  })
})
