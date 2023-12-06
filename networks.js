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
  ethereumSepolia: {
    url: process.env.ETHEREUM_SEPOLIA_RPC_URL || "UNSET",
    gasPrice: undefined,
    nonce: undefined,
    accounts,
    verifyApiKey: process.env.ETHERSCAN_API_KEY || "UNSET",
    chainId: 11155111,
    confirmations: DEFAULT_VERIFICATION_BLOCK_CONFIRMATIONS,
    nativeCurrencySymbol: "ETH",
    linkToken: "0x779877A7B0D9E8603169DdbD7836e478b4624789",
    linkWrapper: "0xab18414CD93297B0d12ac29E63Ca20f515b3DB46",
    linkPriceFeed: "0x42585eD362B3f1BCa95c640FdFf35Ef899212734", // LINK/ETH
    functionsRouter: "0xb83E47C2bC239B3bf370bc41e1459A34b41238D0",
    ccipRouter: "0xD0daae2231E9CB96b94C8512223533293C3693Bf",
    donId: "fun-ethereum-sepolia-1",
    chainSelector: "16015286601757825753",
    ccipToken: "0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05",
    implementation: "",
    gatewayUrls: [
      "https://01.functions-gateway.testnet.chain.link/",
      "https://02.functions-gateway.testnet.chain.link/",
    ],
  },
  polygonMumbai: {
    url: process.env.POLYGON_MUMBAI_RPC_URL || "UNSET",
    gasPrice: 20_000_000_000,
    nonce: undefined,
    accounts,
    verifyApiKey: process.env.POLYGONSCAN_API_KEY || "UNSET",
    chainId: 80001,
    confirmations: DEFAULT_VERIFICATION_BLOCK_CONFIRMATIONS,
    nativeCurrencySymbol: "MATIC",
    linkToken: "0x326C977E6efc84E512bB9C30f76E30c160eD06FB",
    linkWrapper: "0x99aFAf084eBA697E584501b8Ed2c0B37Dd136693",
    linkPriceFeed: "0x12162c3E810393dEC01362aBf156D7ecf6159528", // LINK/MATIC
    functionsRouter: "0x6E2dc0F9DB014aE19888F539E59285D2Ea04244C",
    ccipRouter: "0x70499c328e1E2a3c41108bd3730F6670a44595D1",
    implementation: "0xDc59057716677afE37755e8aA256c8d852D62f64",
    chainSelector: "12532609583862916517",
    donId: "fun-polygon-mumbai-1",
    ccipToken: "0xf1E3A5842EeEF51F2967b3F05D45DD4f4205FF40",
    gatewayUrls: [
      "https://01.functions-gateway.testnet.chain.link/",
      "https://02.functions-gateway.testnet.chain.link/",
    ],
  },
  avalancheFuji: {
    url: process.env.AVALANCHE_FUJI_RPC_URL || "UNSET",
    gasPrice: undefined,
    nonce: undefined,
    accounts,
    verifyApiKey: process.env.FUJI_SNOWTRACE_API_KEY || "UNSET",
    chainId: 43113,
    confirmations: DEFAULT_VERIFICATION_BLOCK_CONFIRMATIONS,
    nativeCurrencySymbol: "AVAX",
    linkToken: "0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846",
    linkWrapper: "0x9345AC54dA4D0B5Cda8CB749d8ef37e5F02BBb21",
    linkPriceFeed: "0x79c91fd4F8b3DaBEe17d286EB11cEE4D83521775", // LINK/AVAX
    functionsRouter: "0xA9d587a00A31A52Ed70D6026794a8FC5E2F5dCb0",
    relRegistry: "0xFD6a2699FFd3293c646498388077B66b2e459130",
    zexcraftNft: "0xAa25e4A9db1F3e493B9a20279572e4F15Ce6eEa2",
    mintFee: "1234567890",
    accountRegistry: "0xF1D62f668340323a6533307Bb0e44600783BE5CA",
    relationship: "0x649d81f1A8F4097eccA7ae1076287616E433c5E8",
    baseChainAddress: "0x2BB1f234D6889B0dc3cE3a4A1885AcfE1DA30936",
    implementation: "0x1a047212AA2B57a4D52cA0c6876021f53aB89C66",
    donIdHash: "0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000",
    chainSelector: "14767482510784806043",
    donId: "fun-avalanche-fuji-1",
    ccipRouter: "0x554472a2720e5e7d5d3c817529aba05eed5f82d8",
    gatewayUrls: [
      "https://01.functions-gateway.testnet.chain.link/",
      "https://02.functions-gateway.testnet.chain.link/",
    ],
  },
  optimismGoerli: {
    url: process.env.OPTIMSIM_GOERLI_RPC_URL || "UNSET",
    gasPrice: undefined,
    nonce: undefined,
    accounts,
    verifyApiKey: process.env.OPTIMISM_API_KEY || "UNSET",
    chainId: 11155111,
    confirmations: DEFAULT_VERIFICATION_BLOCK_CONFIRMATIONS,
    nativeCurrencySymbol: "ETH",
    linkToken: "0xdc2CC710e42857672E7907CF474a69B63B93089f",
    linkWrapper: "0xab18414CD93297B0d12ac29E63Ca20f515b3DB46",
    implementation: "",
    chainSelector: "2664363617261496610",
    ccipToken: "0xaBfE9D11A2f1D61990D1d253EC98B5Da00304F16",
    ccipRouter: "0xeb52e9ae4a9fb37172978642d4c141ef53876f26",
  },
  binanceTestnet: {
    url: process.env.BINANCE_RPC_URL || "UNSET",
    gasPrice: undefined,
    nonce: undefined,
    accounts,
    verifyApiKey: process.env.BINANCE_API_KEY || "UNSET",
    chainId: 11155111,
    confirmations: DEFAULT_VERIFICATION_BLOCK_CONFIRMATIONS,
    nativeCurrencySymbol: "ETH",
    linkToken: "0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06",
    implementation: "",
    chainSelector: "13264668187771770619",
    ccipToken: "0xbfa2acd33ed6eec0ed3cc06bf1ac38d22b36b9e9",
    ccipRouter: "0x9527e2d01a3064ef6b50c1da1c0cc523803bcff2",
  },
  baseGoerliTestnet: {
    url: process.env.BASE_GOERLI_RPC_URL || "UNSET",
    gasPrice: undefined,
    nonce: undefined,
    accounts,
    verifyApiKey: process.env.BASE_API_KEY || "UNSET",
    chainId: 11155111,
    confirmations: DEFAULT_VERIFICATION_BLOCK_CONFIRMATIONS,
    nativeCurrencySymbol: "ETH",
    chainSelector: "5790810961207155433",
    implementation: "",
    linkToken: "0xd886e2286fd1073df82462ea1822119600af80b6",
    ccipToken: "0xbf9036529123de264bfa0fc7362fe25b650d4b16",
    ccipRouter: "0xa8c0c11bf64af62cdca6f93d3769b88bdd7cb93d",
  },
  // localFunctionsTestnet is updated dynamically by scripts/startLocalFunctionsTestnet.js so it should not be modified here
  localFunctionsTestnet: {
    url: "http://localhost:8545/",
    accounts,
    confirmations: 1,
    nativeCurrencySymbol: "ETH",
    linkToken: "0x94d3C68A91C972388d7863D25EDD2Be7e2F21F21",
    functionsRouter: "0xCbfD616baE0F13EFE0528c446184C9C0EAa8040e",
    donId: "local-functions-testnet",
  },
}

module.exports = {
  networks,
}
