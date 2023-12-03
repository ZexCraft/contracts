const fs = require("fs")
const { Location, ReturnType, CodeLanguage } = require("@chainlink/functions-toolkit")

const newbornGenerate = ["NEW_BORN", "Rich African with Poor American", "76"]

const breedGenerate = [
  "BREED",
  "https://bafybeid7whref5corljy6rntodoqjvj6qi2d42vcebbqccwobh6wrq63oy.ipfs.nftstorage.link/metadata.json",
  "https://bafybeifhofputngb7k3zqpl5otnv4utpvse66sbzutxsg6bkozks6ytt7m.ipfs.dweb.link/354",
  "87",
]

const midjourney = ["NEW_BORN", "A gorilla in a classroom", "90", "IGvB83r51EVPRnnYS19X"]

// Configure the request by setting the fields below
const requestConfig = {
  // String containing the source code to be executed
  source: fs.readFileSync("./generate-zexcraft-nft.js").toString(),
  //source: fs.readFileSync("./API-request-example.js").toString(),
  // Location of source code (only Inline is currently supported)
  codeLocation: Location.Inline,
  // Optional. Secrets can be accessed within the source code with `secrets.varName` (ie: secrets.apiKey). The secrets object can only contain string values.
  secrets: {
    nftStorageApiKey: process.env.NFT_STORAGE_API_KEY ?? "",
    midjourneyApiKey: process.env.MIDJOURNEY_API_KEY ?? "",
  },
  // Optional if secrets are expected in the sourceLocation of secrets (only Remote or DONHosted is supported)
  secretsLocation: Location.DONHosted,
  // Args (string only array) can be accessed within the source code with `args[index]` (ie: args[0]).
  args: newbornGenerate,
  // Code language (only JavaScript is currently supported)
  codeLanguage: CodeLanguage.JavaScript,
  // Expected type of the returned value
  expectedReturnType: ReturnType.string,
}

module.exports = requestConfig
