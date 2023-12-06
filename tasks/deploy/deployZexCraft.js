const { types } = require("hardhat/config")
const { networks } = require("../../networks")
const fs = require("fs")

task("deploy-zexcraft", "Deploys the ZexCraftNFT contract")
  .addOptionalParam("verify", "Set to true to verify contract", false, types.boolean)
  .setAction(async (taskArgs) => {
    console.log(`Deploying ZexCraftNFT contract to ${network.name}`)

    const linkToken = networks.avalancheFuji.linkToken
    const linkWrapper = networks.avalancheFuji.linkWrapper
    const router = networks.avalancheFuji.functionsRouter
    const accountRegistry = networks.avalancheFuji.accountRegistry
    const donId = networks.avalancheFuji.donIdHash
    const relRegistry = networks.avalancheFuji.relRegistry
    const generateSourceCode = fs.readFileSync("./generate-zexcraft-nft.js").toString()
    const fetchSourceCode = fs.readFileSync("./fetch-zexcraft-nft.js").toString()
    const callbackGasLimit = "300000"
    const mintFee = networks.avalancheFuji.mintFee
    const baseChainAddress = networks.avalancheFuji.baseChainAddress

    console.log([
      linkToken,
      linkWrapper,
      router,
      accountRegistry,
      donId,
      relRegistry,
      generateSourceCode.length != 0,
      fetchSourceCode.length != 0,
      callbackGasLimit,
      mintFee,
      baseChainAddress,
    ])
    console.log("\n__Compiling Contracts__")
    await run("compile")

    const zexCraftContractFactory = await ethers.getContractFactory("ZexCraftNFT")
    const zexCraftContract = await zexCraftContractFactory.deploy([
      linkToken,
      linkWrapper,
      router,
      donId,
      relRegistry,
      generateSourceCode,
      fetchSourceCode,
      callbackGasLimit,
      mintFee,
      baseChainAddress,
      accountRegistry,
    ])

    console.log(
      `\nWaiting ${networks[network.name].confirmations} blocks for transaction ${
        zexCraftContract.deployTransaction.hash
      } to be confirmed...`
    )

    await zexCraftContract.deployTransaction.wait(networks[network.name].confirmations)

    console.log("\nDeployed ZexCraftNFT contract to:", zexCraftContract.address)

    if (network.name === "localFunctionsTestnet") {
      return
    }

    const verifyContract = taskArgs.verify
    if (
      network.name !== "localFunctionsTestnet" &&
      verifyContract &&
      !!networks[network.name].verifyApiKey &&
      networks[network.name].verifyApiKey !== "UNSET"
    ) {
      try {
        console.log("\nVerifying contract...")
        await run("verify:verify", {
          address: zexCraftContract.address,
          constructorArguments: [
            [
              linkToken,
              linkWrapper,
              router,
              donId,
              relRegistry,
              generateSourceCode,
              fetchSourceCode,
              callbackGasLimit,
              mintFee,
              baseChainAddress,
              accountRegistry,
            ],
          ],
        })
        console.log("Contract verified")
      } catch (error) {
        if (!error.message.includes("Already Verified")) {
          console.log(
            "Error verifying contract.  Ensure you are waiting for enough confirmation blocks, delete the build folder and try again."
          )
          console.log(error)
        } else {
          console.log("Contract already verified")
        }
      }
    } else if (verifyContract && network.name !== "localFunctionsTestnet") {
      console.log(
        "\nPOLYGONSCAN_API_KEY, ETHERSCAN_API_KEY or FUJI_SNOWTRACE_API_KEY is missing. Skipping contract verification..."
      )
    }

    console.log(`\ZexCraftNFT contract deployed to ${zexCraftContract.address} on ${network.name}`)
  })
