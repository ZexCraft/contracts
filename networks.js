// All supported networks and related contract addresses are defined here.
//
// LINK token addresses: https://docs.chain.link/resources/link-token-contracts/
// Price feeds addresses: https://docs.chain.link/data-feeds/price-feeds/addresses
// Chain IDs: https://chainlist.org/?testnets=true

// Loads environment variables from .env.enc file (if it exists)
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
    implementation: "0xD919F79062Ff8492e043c42148EE66AFF08CBBe0",
    registry: "0x1fA76405DCBC8b9C9407809C585358b616527e04",
    relImplementation: "0xcC4203412a962fEFC2e41003bB1Ae296Ff7FE8f3",
    relRegistry: "0x70D29654582d1e969D34f99E6b277E19dc2Cb683",
    pegoCraft: "0x0a41A53B831B111782B0e107E6b54Af2950C12aF",
    mintFee: "100000000000000000",
    craftToken: "0x7531bfe7268120e006a0088a1fcd36651aacb4f7",
  },
  pegoMainnet: {
    url: process.env.PEGO_MAINNET_RPC_URL || "UNSET",
    gasPrice: 20_000_000_000,
    nonce: undefined,
    accounts,
    verifyApiKey: "UNSET",
    chainId: 20201022,
    confirmations: 5,
    nativeCurrencySymbol: "PG",
  },
}

module.exports = {
  networks,
}
