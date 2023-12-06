const { networks } = require("../../networks")

task("deploy-relationship", "Deploys the ZexCraftRelationship contract")
  .addOptionalParam("verify", "Set to true to verify contract", false, types.boolean)
  .setAction(async (taskArgs) => {
    console.log(`Deploying ZexCraftRelationship contract to ${network.name}`)

    console.log("\n__Compiling Contracts__")
    await run("compile")

    const params = {
      router: networks[network.name].ccipRouter,
      mintFee: networks.avalancheFuji.mintFee,
    }

    const relationshipFactory = await ethers.getContractFactory("ZexCraftRelationship")
    const relationship = await relationshipFactory.deploy(params.router, params.mintFee)

    console.log(
      `\nWaiting ${networks[network.name].confirmations} blocks for transaction ${
        relationship.deployTransaction.hash
      } to be confirmed...`
    )

    await relationship.deployTransaction.wait(networks[network.name].confirmations)

    console.log("\nDeployed ZexCraftRelationship contract to:", relationship.address)

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
          address: relationship.address,
          constructorArguments: [params.router, params.mintFee],
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

    console.log(`\ZexCraftRelationship contract deployed to ${relationship.address} on ${network.name}`)
  })
