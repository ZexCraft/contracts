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
    implementation: "0x54284d3972e01931022fBbb8EAf6D167cB6e0Db8",
    registry: "0x393B5c9b6Cc5c484C0Be085DC413A0fB95f1eFfA",
    relImplementation: "0x874F9914c3e5cA477cD858496a7078FAAAF92a8d",
    relRegistry: "0x23439a15001903bDAcE6d3a4319c1fF438421334",
    zexCraft: "0x08F947784232C623Ea52cA9f9E39B58Be7d14605",
    mintFee: "100000000000000000",
    craftToken: "0x89d5da61548205E755874d7f67Ad00F90680440d",
  },
  victionTestnet: {
    url: "https://rpc-testnet.viction.xyz",
    gasPrice: 400_000_000,
    nonce: undefined,
    accounts,
    verifyApiKey: process.env.VICTION_API_KEY || "UNSET",
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
    verifyApiKey: process.env.VICTION_API_KEY || "UNSET",
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
