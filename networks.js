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
    implementation: "0x29f42484e15709b60cDC89A1f102fa9a563Cf608",
    registry: "0x170d6BC5cb1FF0f44dA7D59fC0DEEa6c42a5f412",
    relImplementation: "0xBE3D118760d9be86688D88929c2122cEc9Ec4635",
    relRegistry: "0x4393eD225A2F48C27eA6CeBec139190cb8EA8A5F",
    inCraft: "0x9FafD4cB45410a931b538F1D97EFCC28b147E449",
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
