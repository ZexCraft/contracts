const { types } = require("hardhat/config")
const { networks } = require("../../networks")
const fs = require("fs")

task("deploy-pegocraft", "Deploys the PegoCraftNFT contract")
  .addOptionalParam("verify", "Set to true to verify contract", false, types.boolean)
  .setAction(async (taskArgs) => {
    console.log(`Deploying PegoCraftNFT contract to ${network.name}`)

    const params = {
      relRegistry: networks[network.name].relRegistry,
      mintFee: networks[network.name].mintFee,
    }

    console.log("\n__Compiling Contracts__")
    await run("compile")

    console.log(params.relRegistry)
    console.log(params.mintFee)
    const pegoCraftContractFactory = await ethers.getContractFactory("PegoCraftNFT")
    const pegoCraftContract = await pegoCraftContractFactory.deploy(params.relRegistry, params.mintFee)

    console.log(
      `\nWaiting ${networks[network.name].confirmations} blocks for transaction ${
        pegoCraftContract.deployTransaction.hash
      } to be confirmed...`
    )

    await pegoCraftContract.deployTransaction.wait(networks[network.name].confirmations)

    console.log("\nDeployed PegoCraftNFT contract to:", pegoCraftContract.address)

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
          address: pegoCraftContract.address,
          constructorArguments: [params.relRegistry, params.mintFee],
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

    console.log(`\PegoCraftNFT contract deployed to ${pegoCraftContract.address} on ${network.name}`)
  })
