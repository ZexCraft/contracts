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
      pegoMainnet: networks.pegoMainnet.verifyApiKey,
      pegoTestnet: networks.pegoTestnet.verifyApiKey,
    },
    customChains: [
      {
        network: "pegoMainnet",
        chainId: 20201022,
        urls: {
          apiURL: "https://scan.pego.network/api",
          browserURL: "https://scan.pego.network/",
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
