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
    implementation: "0x5Ca8b540FCc09ac4d5719cf645c8E636984900F0",
    registry: "0x6036BdC357A2dF2a69621e658A4Bb951B60ca799",
    relImplementation: "0x81692a7278869Bb5bf98A1adD937fdB7EEfFe09c",
    relRegistry: "0x4a0DC91781A116e83770A17AD09b63fa3E50d7Ce",
    inCraft: "0xC7297019FCDA5774c22180cd7E1801fed7EC10A9",
    mintFee: "100000000000000000",
    craftToken: "0xf514E2910c6f78c1Dc6B765A0d06adfd75C8450c",
  },
  inEvmTestnet: {
    url: "https://inevm-rpc.caldera.dev/",
    gasPrice: 40_000_000_00,
    nonce: undefined,
    accounts,
    verifyApiKey: process.env.POLYGONSCAN_API_KEY || "UNSET",
    chainId: 1738,
    confirmations: 2,
    nativeCurrencySymbol: "INJ",
    implementation: "0x16CBC6Cb38D19B73A3b545109c70b2031d20EA37",
    registry: "0xd37ca03a13bD2725306Fec4071855EE556037e2e",
    relImplementation: "0x4ab8f50796b059aE5C8b8534afC6bb4c84912ff6",
    relRegistry: "0x7125e097a72cCf547ED6e9e98bCc09BE3AC61997",
    inCraft: "0x50751BD8d7b0a84c422DE96A56426a370F31a42D",
    mintFee: "100000000000000000",
    craftToken: "0x08AC2b69feB202b34aD7c65E5Ac876E901CA6216",
  },
}

module.exports = {
  networks,
}
