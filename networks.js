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
    implementation: "0x8A0B22dB8790BbeFD03b1839E5a929baA82ABE4a",
    registry: "0x2209217F03cAd66946C66Dc490828db9c8941b48",
    relImplementation: "0x4ce1F07aa40780d43f3fEF65fedF2899E85320B1",
    relRegistry: "0xb84563d2e11Ae3E2119AA50cEf7039B006FD685E",
    zexCraft: "0x7B2C51d3b9e93480F28A330a0ee938C2182cD486",
    mintFee: "100000000000000000",
    craftToken: "0xe96C5844AF134f44153ee86295Fc964661074Bbd",
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
