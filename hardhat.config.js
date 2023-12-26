require("@nomicfoundation/hardhat-toolbox")
require("hardhat-contract-sizer")
require("./tasks")
const { networks } = require("./networks")

// Enable gas reporting (optional)
const REPORT_GAS = process.env.REPORT_GAS?.toLowerCase() === "true" ? true : false

const SOLC_SETTINGS = {
  optimizer: {
    enabled: true,
    runs: 1_000,
  },
}

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.19",
        settings: SOLC_SETTINGS,
      },
      {
        version: "0.8.20",
        settings: SOLC_SETTINGS,
      },
    ],
  },
  networks: {
    ...networks,
  },
  etherscan: {
    apiKey: {
      polygonMumbai: networks.polygonMumbai.verifyApiKey,
      viction: networks.viction.verifyApiKey,
      victionTestnet: networks.victionTestnet.verifyApiKey,
    },
    customChains: [
      {
        network: "viction",
        chainId: 88,
        urls: {
          apiURL: "https://www.vicscan.xyz/api/contract/hardhat/verify",
          browserURL: "https://vicscan.xyz",
        },
      },
      {
        network: "victionTestnet",
        chainId: 89,
        urls: {
          apiURL: "https://scan-api-testnet.viction.xyz/api/contract/hardhat/verify",
          browserURL: "https://testnet.vicscan.xyz",
        },
      },
    ],
  },
  gasReporter: {
    enabled: REPORT_GAS,
    currency: "USD",
    outputFile: "gas-report.txt",
    noColors: true,
  },
  contractSizer: {
    runOnCompile: false,
    only: ["FunctionsConsumer", "AutomatedFunctionsConsumer", "FunctionsBillingRegistry"],
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./build/cache",
    artifacts: "./build/artifacts",
  },
  mocha: {
    timeout: 200000, // 200 seconds max for running tests
  },
}
