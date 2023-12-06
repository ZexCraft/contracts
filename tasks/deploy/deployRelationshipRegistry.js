const { networks } = require("../../networks")

task("deploy-relationship-registry", "Deploys the ZexCraftRelationshipRegistry contract")
  .addOptionalParam("verify", "Set to true to verify contract", false, types.boolean)
  .setAction(async (taskArgs) => {
    console.log(`Deploying ZexCraftRelationshipRegistry contract to ${network.name}`)

    console.log("\n__Compiling Contracts__")
    await run("compile")

    const params = {
      router: networks[network.name].accountRegistry,
      relationship: networks[network.name].relationship,
      ccipRouter: networks[network.name].ccipRouter,
      relationship: networks[network.name].zexcraftNft,
    }
    const relationshipFactory = await ethers.getContractFactory("ZexCraftRelationshipRegistry")
    const relationshipRegistry = await relationshipFactory.deploy(
      params.router,
      params.relationship,
      params.ccipRouter,
      params.relationship
    )

    console.log(
      `\nWaiting ${networks[network.name].confirmations} blocks for transaction ${
        relationshipRegistry.deployTransaction.hash
      } to be confirmed...`
    )

    await relationshipRegistry.deployTransaction.wait(networks[network.name].confirmations)

    console.log("\nDeployed ZexCraftRelationshipRegistry contract to:", relationshipRegistry.address)

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
          address: relationshipRegistry.address,
          constructorArguments: [params.router, params.relationship, params.ccipRouter, params.relationship],
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

    console.log(`\ZexCraftRelationshipRegistry contract deployed to ${relationshipRegistry.address} on ${network.name}`)
  })
