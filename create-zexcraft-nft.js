if (secrets.stableCogApiKey == "" || secrets.stableCogApiKey == undefined) {
  throw Error("STABLECOG_API_KEY NOT SET")
}

if (secrets.nftStorageApiKey == "" || secrets.nftStorageApiKey == undefined) {
  throw Error("NFT_STORAGE_API_KEY NOT SET")
}

const type = args[0]
const nounId = args[1]
if (type == "NEW_BORN") {
  const prompt = args[2]
  const image = args[3]
  const rarityNumber = args[4]
  const seed = args[5]

  const rarity = getRarity(rarityNumber)

  const modifiedPrompt = `PRIMARY COLOR: ${rarity.color}. ${prompt}`

  const outputsResponse = await Functions.makeHttpRequest({
    url: `https://api.stablecog.com/v1/image/generation/outputs`,
    method: "GET",
    headers: { Authorization: `Bearer ${secrets.stableCogApiKey}`, "Content-Type": "application/json" },
  })

  // console.log(outputsResponse)

  if (outputsResponse.error) {
    throw Error("API Failed")
  }
  const imageUrl = outputsResponse.data.outputs.filter(
    (output) => output.generation.seed == seed && output.generation.prompt.text == modifiedPrompt
  )[0].generation.outputs[0].image_url

  console.log(imageUrl)

  const props = getQueryParams(image)

  console.log(props)
  const metadata = {
    name: "ZexNOUNS #" + nounId,
    description: "A zex-crafted NOUN NFTs that are bred with other NFTs powered by AI",
    image: imageUrl,
    attributes: [
      {
        trait_type: "head",
        value: props.head,
      },
      {
        trait_type: "background",
        value: props.background,
      },
      {
        trait_type: "body",
        value: props.body,
      },
      {
        trait_type: "accessory",
        value: props.accessory,
      },
      {
        trait_type: "glasses",
        value: props.glasses,
      },
      {
        trait_type: "prompt",
        value: prompt,
      },
      {
        trait_type: "kind",
        value: rarity.name,
      },
      {
        trait_type: "rarity",
        value: rarityNumber,
      },
    ],
  }
  const metadataString = JSON.stringify(metadata, null, 2)

  console.log(metadataString)

  return await storeInIPFS(metadataString)
} else {
  if (secrets.simpleHashApiKey == "" || secrets.simpleHashApiKey == undefined) {
    throw Error("SIMPLE_HASH_API_KEY NOT SET")
  }
  const tokenUri = args[2]
  const chain = args[3]
  const tokenAddress = args[4]
  const tokenId = args[5]
  const rarityNumber = args[6]
  const seed = args[7]

  const foreignNftResponse = await getNFT(chain, tokenAddress, tokenId)

  if (foreignNftResponse.error) {
    throw Error("SimpleHash API Failed")
  }
  // console.log(foreignNftResponse.data)
  let customPrompt = `Combine the init image with the following traits of this ${foreignNftResponse.data.contract.name} NFT to form.`

  foreignNftResponse.data.extra_metadata.attributes.forEach((element) => {
    customPrompt += ` ${element.trait_type}: ${element.value},`
  })

  const rarity = getRarity(rarityNumber)

  const modifiedPrompt = `PRIMARY COLOR: ${rarity.color}. ${customPrompt}`.slice(0, -1)

  console.log(modifiedPrompt)
  const outputsResponse = await Functions.makeHttpRequest({
    url: `https://api.stablecog.com/v1/image/generation/outputs`,
    method: "GET",
    headers: { Authorization: `Bearer ${secrets.stableCogApiKey}`, "Content-Type": "application/json" },
  })

  if (outputsResponse.error) {
    throw Error("StableCog outputs fetch Failed")
  }

  const imageUrl = outputsResponse.data.outputs.filter(
    (output) => output.generation.seed == seed && output.generation.prompt.text == modifiedPrompt
  )[0].generation.outputs[0].image_url

  console.log(imageUrl)

  const nounMetadataResponse = await Functions.makeHttpRequest({
    url: tokenUri,
    method: "GET",
    headers: { "Content-Type": "application/json" },
  })

  if (nounMetadataResponse.error) {
    throw Error("Noun Metadata Fetch Failed")
  }

  const nounMetadata = nounMetadataResponse.data
  console.log(nounMetadata)
  const metadata = {
    name: "ZexNOUNS #" + nounId,
    description: "A zex-crafted NOUN NFTs that are bred with other NFTs powered by AI",
    image: imageUrl,
    attributes: [
      ...nounMetadata.attributes,
      ...foreignNftResponse.data.extra_metadata.attributes.map((attribute) => {
        return {
          trait_type: "foreign " + attribute.trait_type,
          value: "foreign " + attribute.value,
        }
      }),
      {
        trait_type: "kind",
        value: rarity.name,
      },
      {
        trait_type: "rarity",
        value: rarityNumber,
      },
    ],
  }
  const metadataString = JSON.stringify(metadata, null, 2)
  console.log(metadataString)

  return await storeInIPFS(metadataString)
}

function getQueryParams(url) {
  const params = {}
  const queryString = url.split("?")[1]

  if (queryString) {
    const keyValuePairs = queryString.split("&")

    keyValuePairs.forEach((pair) => {
      const [key, value] = pair.split("=")
      params[key] = value
    })
  }

  return params
}

async function getNFT(chain, tokenAddress, tokenId) {
  const url = `https://api.simplehash.com/api/v0/nfts/${chain}/${tokenAddress}/${tokenId}`
  const response = await Functions.makeHttpRequest({
    url: url,
    method: "GET",
    headers: { "X-API-KEY": secrets.simpleHashApiKey, accept: "application/json" },
  })
  return response
}

function getRarity(rarity) {
  if (rarity < 30) {
    return { name: "COMMON", color: "GREY" }
  } else if (rarity < 60) {
    return { name: "UNCOMMON", color: "GREEN" }
  } else if (rarity < 70) {
    return { name: "RARE", color: "BLUE" }
  } else if (rarity < 85) {
    return { name: "EPIC", color: "PURPLE" }
  } else if (rarity < 95) {
    return { name: "LEGENDARY", color: "GOLDEN" }
  } else if (rarity < 100) {
    return { name: "ZEXSTAR", color: "RED" }
  } else {
    return { name: "SPECIAL EDITION", color: "PINK" }
  }
}

async function storeInIPFS(metadataString) {
  const storeMetadataRequest = Functions.makeHttpRequest({
    url: `https://zixins-be1.adaptable.app/auth/store`,
    method: "POST",
    headers: { Authorization: `Bearer ${secrets.nftStorageApiKey}`, "Content-Type": "application/json" },
    data: { metadataString: metadataString },
  })
  const [storeMetadataResponse] = await Promise.all([storeMetadataRequest])
  console.log(storeMetadataResponse)

  if (!storeMetadataResponse.error) {
    const metadataUrl = "https://" + storeMetadataResponse.data.value.cid + ".ipfs.nftstorage.link/metadata.json"
    console.log("Returning url: " + metadataUrl)
    return Functions.encodeString(metadataUrl)
  } else {
    throw Error(storeMetadataResponse.data)
  }
}
