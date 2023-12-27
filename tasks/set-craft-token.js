const { networks } = require("../networks")
task("set-craft-token", "Sets Craft Token Address to ZexCraft").setAction(async (taskArgs, hre) => {
  try {
    const craftToken = "0xC044FCe37927A0Cb55C7e57425Fe3772181228a6"
    const functionHash = ethers.utils.id("setCraftToken(address)").slice(0, 10)
    console.log(functionHash)

    const encodedData = ethers.utils.defaultAbiCoder.encode(["address"], [craftToken]).slice(2)
    console.log(functionHash + encodedData)
  } catch (error) {
    console.log(error)
  }
})
