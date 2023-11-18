const fs = require("fs")
const { Location, ReturnType, CodeLanguage } = require("@chainlink/functions-toolkit")

const newborn = [
  "NEW_BORN",
  "1",
  "It should like an NFT. Star Wars",
  "https://noun-api.com/beta/pfp?head=119&glasses=18&background=0&body=5&accessory=2",
  "20",
  "2033421602",
]

const breed = [
  "BREED",
  "3",
  "https://bafybeid7whref5corljy6rntodoqjvj6qi2d42vcebbqccwobh6wrq63oy.ipfs.nftstorage.link/metadata.json",
  "ethereum",
  "0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d",
  "8334",
  "87",
  "660529954",
]

// Configure the request by setting the fields below
const requestConfig = {
  // String containing the source code to be executed
  source: fs.readFileSync("./create-zexnouns.js").toString(),
  //source: fs.readFileSync("./API-request-example.js").toString(),
  // Location of source code (only Inline is currently supported)
  codeLocation: Location.Inline,
  // Optional. Secrets can be accessed within the source code with `secrets.varName` (ie: secrets.apiKey). The secrets object can only contain string values.
  secrets: {
    stableCogApiKey: process.env.STABLECOG_API_KEY ?? "",
    nftStorageApiKey: process.env.NFT_STORAGE_API_KEY ?? "",
    simpleHashApiKey: process.env.SIMPLE_HASH_API_KEY ?? "",
  },
  // Optional if secrets are expected in the sourceLocation of secrets (only Remote or DONHosted is supported)
  secretsLocation: Location.DONHosted,
  // Args (string only array) can be accessed within the source code with `args[index]` (ie: args[0]).
  args: newborn,
  // Code language (only JavaScript is currently supported)
  codeLanguage: CodeLanguage.JavaScript,
  // Expected type of the returned value
  expectedReturnType: ReturnType.string,
}

module.exports = requestConfig
