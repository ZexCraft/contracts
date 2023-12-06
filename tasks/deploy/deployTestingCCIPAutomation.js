const { networks } = require("../../networks")

task("deploy-testing-ccip-automation", "Deploys the TestingCCIPAutomation contract")
  .addOptionalParam("verify", "Set to true to verify contract", false, types.boolean)
  .setAction(async (taskArgs) => {
    console.log(`Deploying TestingCCIPAutomation contract to ${network.name}`)

    console.log("\n__Compiling Contracts__")
    await run("compile")

    const params = {
      router: networks.ethereumSepolia.ccipRouter,
      link: networks.ethereumSepolia.linkToken,
      zexCraftNftContract: "0x0429A2Da7884CA14E53142988D5845952fE4DF6a",
      baseChainAddress: "0x9Fa2f0872498f56Fec437d92D66842f162c6B922",
      mintFee: "10000000",
      ccipToken: "0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05",
      destinationChainSelector: "14767482510784806043",
    }

    const testingContractFactory = await ethers.getContractFactory("TestingCCIPAutomation")
    const testingContract = await testingContractFactory.deploy(
      params.router,
      params.link,
      params.zexCraftNftContract,
      params.baseChainAddress,
      params.mintFee,
      params.ccipToken,
      params.destinationChainSelector
    )

    console.log(
      `\nWaiting ${networks[network.name].confirmations} blocks for transaction ${
        testingContract.deployTransaction.hash
      } to be confirmed...`
    )

    await testingContract.deployTransaction.wait(networks[network.name].confirmations)

    console.log("\nDeployed TestingCCIPAutomation contract to:", testingContract.address)

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
          address: testingContract.address,
          constructorArguments: [
            params.router,
            params.link,
            params.zexCraftNftContract,
            params.baseChainAddress,
            params.mintFee,
            params.ccipToken,
            params.destinationChainSelector,
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

    console.log(`\n TestingCCIPAutomation contract deployed to ${testingContract.address} on ${network.name}`)
  })
