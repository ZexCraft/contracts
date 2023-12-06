const { networks } = require("../../networks")

task("deploy-crosschain-mint", "Deploys the ZexCraftCrosschainMint contract")
  .addOptionalParam("verify", "Set to true to verify contract", false, types.boolean)
  .setAction(async (taskArgs) => {
    console.log(`Deploying ZexCraftCrosschainMint contract to ${network.name}`)

    console.log("\n__Compiling Contracts__")
    await run("compile")

    const params = {
      router: networks[network.name].ccipRouter,
      link: networks[network.name].linkToken,
      zexcraftNft: networks.avalancheFuji.zexcraftNft,
      baseChainAddress: networks.avalancheFuji.baseChainAddress,
      mintFee: networks.avalancheFuji.mintFee,
      ccipToken: networks[network.name].ccipToken,
    }
    console.log(params)
    const crosschainMintFactory = await ethers.getContractFactory("ZexCraftCrosschainMint")
    const crosschainMint = await crosschainMintFactory.deploy(
      params.router,
      params.link,
      params.zexcraftNft,
      params.baseChainAddress,
      params.mintFee,
      params.ccipToken
    )

    console.log(
      `\nWaiting ${networks[network.name].confirmations} blocks for transaction ${
        crosschainMint.deployTransaction.hash
      } to be confirmed...`
    )

    await crosschainMint.deployTransaction.wait(networks[network.name].confirmations)

    console.log("\nDeployed ZexCraftCrosschainMint contract to:", crosschainMint.address)

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
          address: crosschainMint.address,
          constructorArguments: [
            params.router,
            params.link,
            params.zexcraftNft,
            params.baseChainAddress,
            params.mintFee,
            params.ccipToken,
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

    console.log(`\n ZexCraftCrosschainMint contract deployed to ${crosschainMint.address} on ${network.name}`)
  })
