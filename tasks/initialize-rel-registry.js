const { networks } = require("../networks")
task("initialize-rel-registry", "Initalizes Relationship registry").setAction(async (taskArgs, hre) => {
  try {
    const craftToken = "0x08AC2b69feB202b34aD7c65E5Ac876E901CA6216"
    const zexCraft = "0x50751BD8d7b0a84c422DE96A56426a370F31a42D"
    const functionHash = ethers.utils.id("initialize(address,address)").slice(0, 10)
    console.log(functionHash)

    const encodedData = ethers.utils.defaultAbiCoder.encode(["address", "address"], [zexCraft, craftToken]).slice(2)
    console.log(functionHash + encodedData)
  } catch (error) {
    console.log(error)
  }
})
