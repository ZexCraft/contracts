const { networks } = require("../networks")
task("set-craft-token", "Sets Craft Token Address to ZexCraft").setAction(async (taskArgs, hre) => {
  try {
    const craftToken = "0x08AC2b69feB202b34aD7c65E5Ac876E901CA6216"
    const functionHash = ethers.utils.id("setCraftToken(address)").slice(0, 10)
    console.log(functionHash)

    const encodedData = ethers.utils.defaultAbiCoder.encode(["address"], [craftToken]).slice(2)
    console.log(functionHash + encodedData)
  } catch (error) {
    console.log(error)
  }
})
