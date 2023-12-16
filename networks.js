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
    implementation: "0x31555fe83F79eE8498e986Ed11fC53702c2495E6",
    registry: "0xB127bd20bf4c7723148B588e10B5d3A1E2E86242",
    relImplementation: "0x8655c4806E362B58c6E3C1676c5c7D99170Aa101",
    relRegistry: "0xa182fBb163323137eBd9a1d96990264E80494A10",
    pegoCraft: "0x11C6E5451d010C43e04240EFC4696AC763fac19f",
    mintFee: "100000000000000000",
    craftToken: "0xD1dfbEd2a946a81324ed59D4C1396BB65aBa99B0",
  },
  pegoMainnet: {
    url: process.env.PEGO_MAINNET_RPC_URL || "UNSET",
    gasPrice: 50_000_000_00_00,
    nonce: undefined,
    accounts,
    verifyApiKey: "UNSET",
    chainId: 20201022,
    confirmations: 5,
    nativeCurrencySymbol: "PG",
    implementation: "0x1A68260E0177a6dDaA4a97917555F1b81FB157c8",
    registry: "0x05E8C37c10a8D9e5681A6b8E10155a8452B06963",
    relImplementation: "0x8241A2943F000ADb8edEbF596627F41a7f56e629",
    relRegistry: "0x0c8b10bA7bA983AD927DDf3C426a661e280DC243",
    pegoCraft: "0x1e167D5Cc4F0CaD6d12c5Aea356e780dE60dE437",
    mintFee: "100000000000000000",
    relRegistry: "0x0c8b10bA7bA983AD927DDf3C426a661e280DC243",
    pegoCraft: "0x1e167D5Cc4F0CaD6d12c5Aea356e780dE60dE437",
    craftToken: "0x5193326E0fFD65C4433C2589466071dd831cd838",
  },
  pegoTestnet: {
    url: process.env.PEGO_TESTNET_RPC_URL || "UNSET",
    gasPrice: 50_000_000_00_00,
    nontce: undefined,
    accounts,
    verifyApiKey: "UNSET",
    chainId: 123456,
    confirmations: 5,
    nativeCurrencySymbol: "tPG",
    implementation: "0x51b83a5Eb4786295F9F5B62c247287456C3E69e8",
    registry: "0x2BB1f234D6889B0dc3cE3a4A1885AcfE1DA30936",
    mintFee: "100000000000000000",
    relImplementation: "0xFD6a2699FFd3293c646498388077B66b2e459130",
    relRegistry: "0xAa25e4A9db1F3e493B9a20279572e4F15Ce6eEa2",
    pegoCraft: "0x649d81f1A8F4097eccA7ae1076287616E433c5E8",
    craftToken: "0x9b7a42bFE8f8Df9d43f368Baf9480fB7193Cf06a",
  },
}

module.exports = {
  networks,
}
