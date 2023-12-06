const { networks } = require("../../networks")

task("deploy-crosschain-implementation", "Deploys the ZexCraftERC6551AccountCrossChain contract")
  .addOptionalParam("verify", "Set to true to verify contract", false, types.boolean)
  .setAction(async (taskArgs) => {
    console.log(`Deploying ZexCraftERC6551AccountCrossChain contract to ${network.name}`)

    console.log("\n__Compiling Contracts__")
    await run("compile")

    const params = {
      router: networks[network.name],
      link: "",
      relRegistry: "",
      ccipToken: "",
      sourceChainSelector: "",
    }

    const crosschainAccountFactory = await ethers.getContractFactory("ZexCraftERC6551AccountCrossChain")
    const crosschainAccount = await crosschainAccountFactory.deploy()

    console.log(
      `\nWaiting ${networks[network.name].confirmations} blocks for transaction ${
        crosschainAccount.deployTransaction.hash
      } to be confirmed...`
    )

    await crosschainAccount.deployTransaction.wait(networks[network.name].confirmations)

    console.log("\nDeployed ZexCraftERC6551AccountCrossChain contract to:", crosschainAccount.address)

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
          address: crosschainAccount.address,
          constructorArguments: [],
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

    console.log(
      `\n ZexCraftERC6551AccountCrossChain contract deployed to ${crosschainAccount.address} on ${network.name}`
    )
  })
