const { networks } = require("../networks")
task("initialize-rel-registry", "Initalizes Relationship registry").setAction(async (taskArgs, hre) => {
  try {
    const craftToken = "0xC044FCe37927A0Cb55C7e57425Fe3772181228a6"
    const zexCraft = "0xc6b011774FE1393AE254d19456e76F0f1b5B09Eb"
    const functionHash = ethers.utils.id("initialize(address,address)").slice(0, 10)
    console.log(functionHash)

    const encodedData = ethers.utils.defaultAbiCoder.encode(["address", "address"], [zexCraft, craftToken]).slice(2)
    console.log(functionHash + encodedData)
  } catch (error) {
    console.log(error)
  }
})
