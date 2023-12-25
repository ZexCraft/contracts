require("@chainlink/env-enc").config()

const DEFAULT_VERIFICATION_BLOCK_CONFIRMATIONS = 3

const MINT_FEE = "100000000000000000"

const npmCommand = process.env.npm_lifecycle_event
const isTestEnvironment = npmCommand == "test" || npmCommand == "test:unit"

// Set EVM private keys (required)
const PRIVATE_KEY = process.env.PRIVATE_KEY

// TODO @dev - set this to run the accept.js task.
const SECOND_PRIVATE_KEY = process.env.PRIVATE_KEY_2

if (!isTestEnvironment && !PRIVATE_KEY) {
  throw Error("Set the PRIVATE_KEY environment variable with your EVM wallet private key")
}

const accounts = []
if (PRIVATE_KEY) {
  console.log("PRIVATE KEY 1 SET")
  accounts.push(PRIVATE_KEY)
}
if (SECOND_PRIVATE_KEY) {
  console.log("PRIVATE KEY 2 SET")
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
    implementation: "0x80db663024Ef080De87d2A1255ef54aa88b723b4",
    registry: "0x3633e5F44b62fBF534aADD53675045973e3dfE43",
    relImplementation: "0xf09405de084E358717458AEC32b64A9114AB7bB2",
    relRegistry: "0x39917E6C7E06D46Ff4B86A817B2bE0a004572994",
    zexCraft: "0x936889518ab0F1665E042679869a17013E981322",
    mintFee: "100000000000000000",
    craftToken: "0x9284eeb76a806Ee4bdc2F7Ca697a44682a533081",
  },
  victionTestnet: {
    url: "https://rpc-testnet.viction.xyz",
    gasPrice: 400_000_00,
    nonce: undefined,
    accounts,
    verifyApiKey: "tomoscan2023",
    chainId: 89,
    confirmations: DEFAULT_VERIFICATION_BLOCK_CONFIRMATIONS,
    nativeCurrencySymbol: "tVIC",
    implementation: "",
    registry: "",
    relImplementation: "",
    relRegistry: "",
    zexCraft: "",
    mintFee: "100000000000000000",
    craftToken: "",
  },
  viction: {
    url: "https://rpc.viction.xyz",
    gasPrice: 400_000_000,
    nonce: undefined,
    accounts,
    verifyApiKey: "tomoscan2023",
    chainId: 88,
    confirmations: DEFAULT_VERIFICATION_BLOCK_CONFIRMATIONS,
    nativeCurrencySymbol: "VIC",
    implementation: "",
    registry: "",
    relImplementation: "",
    relRegistry: "",
    zexCraft: "",
    mintFee: "100000000000000000",
    craftToken: "",
  },
}

module.exports = {
  networks,
  MINT_FEE,
}
