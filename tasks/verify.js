const { types } = require("hardhat/config")
const { networks } = require("../networks")
const fs = require("fs")
task("verify-contract", "Verifies contract")
  .addParam("contract", "Address of the client contract to verify")
  .setAction(async (taskArgs, hre) => {
    if (network.name === "hardhat") {
      throw Error(
        'This command cannot be used on a local development chain.  Specify a valid network or simulate an Functions request locally with "npx hardhat functions-simulate".'
      )
    }
    const pegoCraft = networks[network.name].pegoCraft

    const constructorArguments = [pegoCraft]

    console.log(`Verifying contract to ${taskArgs.contract}`)

    try {
      console.log("\nVerifying contract...")
      await run("verify:verify", {
        address: taskArgs.contract,
        constructorArguments,
      })
      console.log("Contract verified")
    } catch (error) {
      if (!error.message.includes("Already Verified")) {
        console.log("Error verifying contract.  Delete the build folder and try again.")
        console.log(error)
      } else {
        console.log("Contract already verified")
      }
    }
  })
