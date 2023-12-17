require("@chainlink/env-enc").config()

const DEFAULT_VERIFICATION_BLOCK_CONFIRMATIONS = 3

const npmCommand = process.env.npm_lifecycle_event
const isTestEnvironment = npmCommand == "test" || npmCommand == "test:unit"

// Set EVM private keys (required)
const PRIVATE_KEY = process.env.PRIVATE_KEY

// TODO @dev - set this to run the accept.js task.
const SECOND_PRIVATE_KEY = process.env.SECOND_PRIVATE_KEY

if (!isTestEnvironment && !PRIVATE_KEY) {
  throw Error("Set the PRIVATE_KEY environment variable with your EVM wallet private key")
}

const accounts = []
if (PRIVATE_KEY) {
  accounts.push(PRIVATE_KEY)
}
if (SECOND_PRIVATE_KEY) {
  accounts.push(SECOND_PRIVATE_KEY)
}

const networks = {
  polygonMumbai: {
    url: process.env.POLYGON_MUMBAI_RPC_URL || "UNSET",
    gasPrice: 20_000_000_000,
    nonce: undefined,
    accounts,
    verifyApiKey: process.env.POLYGONSCAN_API_KEY || "UNSET",
    chainId: 80001,
    confirmations: 5,
    nativeCurrencySymbol: "MATIC",
    implementation: "0x6F900fFFBa84a10D45fee7D4fe36aDeF4555b8EB",
    registry: "0xB127bd20bf4c7723148B588e10B5d3A1E2E86242",
    relImplementation: "0x8655c4806E362B58c6E3C1676c5c7D99170Aa101",
    relRegistry: "0xa182fBb163323137eBd9a1d96990264E80494A10",
    inCraft: "0x11C6E5451d010C43e04240EFC4696AC763fac19f",
    mintFee: "100000000000000000",
    craftToken: "0xD1dfbEd2a946a81324ed59D4C1396BB65aBa99B0",
  },
  inEvmTestnet: {
    url: "https://inevm-rpc.caldera.dev/",
    gasPrice: 20_000_000_000,
    nonce: undefined,
    accounts,
    verifyApiKey: process.env.POLYGONSCAN_API_KEY || "UNSET",
    chainId: 1738,
    confirmations: 5,
    nativeCurrencySymbol: "INJ",
    implementation: "",
    registry: "",
    relImplementation: "",
    relRegistry: "",
    inCraft: "",
    mintFee: "100000000000000000",
    craftToken: "",
  },
}

module.exports = {
  networks,
}
