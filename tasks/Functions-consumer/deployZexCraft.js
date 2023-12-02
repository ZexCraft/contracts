const { types } = require("hardhat/config")
const { networks } = require("../../networks")
const fs = require("fs")

task("functions-deploy-zexcraft", "Deploys the ZexCraftNFT contract")
  .addOptionalParam("verify", "Set to true to verify contract", false, types.boolean)
  .setAction(async (taskArgs) => {
    console.log(`Deploying ZexCraftNFT contract to ${network.name}`)

    const linkToken = networks[network.name]["linkToken"]
    const linkWrapper = networks[network.name]["linkWrapper"]
    const router = networks[network.name]["functionsRouter"]
    const implementation = networks[network.name]["implementation"]
    const accountRegistry = networks[network.name]["accountRegistry"]
    const donId = "0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000"
    const relRegistry = "0x0429A2Da7884CA14E53142988D5845952fE4DF6a"
    const sourceCode = fs.readFileSync("./create-zexcraft-nft.js").toString()
    const callbackGasLimit = "300000"
    const mintFee = "0"
    const crossChainAddress = "0x0429A2Da7884CA14E53142988D5845952fE4DF6a"

    console.log("\n__Compiling Contracts__")
    await run("compile")

    const zexCraftContractFactory = await ethers.getContractFactory("ZexCraftNFT")
    const zexCraftContract = await zexCraftContractFactory.deploy(
      linkToken,
      linkWrapper,
      router,
      donId,
      relRegistry,
      sourceCode,
      callbackGasLimit,
      mintFee,
      crossChainAddress,
      implementation,
      accountRegistry
    )

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
            linkToken,
            linkWrapper,
            router,
            donId,
            relRegistry,
            sourceCode,
            callbackGasLimit,
            mintFee,
            crossChainAddress,
            implementation,
            accountRegistry,
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
