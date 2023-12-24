require("@chainlink/env-enc").config()

const DEFAULT_VERIFICATION_BLOCK_CONFIRMATIONS = 3

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
    implementation: "0x5Ca8b540FCc09ac4d5719cf645c8E636984900F0",
    registry: "0x6036BdC357A2dF2a69621e658A4Bb951B60ca799",
    relImplementation: "0x81692a7278869Bb5bf98A1adD937fdB7EEfFe09c",
    relRegistry: "0x4a0DC91781A116e83770A17AD09b63fa3E50d7Ce",
    inCraft: "0xC7297019FCDA5774c22180cd7E1801fed7EC10A9",
    mintFee: "100000000000000000",
    craftToken: "0xf514E2910c6f78c1Dc6B765A0d06adfd75C8450c",
  },
  victionTestnet: {
    url: "https://rpc-testnet.viction.xyz",
    gasPrice: 400_000_000,
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
    inCraft: "",
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
    inCraft: "",
    mintFee: "100000000000000000",
    craftToken: "",
  },
}

module.exports = {
  networks,
}
