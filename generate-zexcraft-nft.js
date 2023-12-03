if (secrets.midjourneyApiKey == "" || secrets.midjourneyApiKey == undefined) {
  throw Error("MIDJOURNEY_API_KEY NOT SET")
}

if (secrets.nftStorageApiKey == "" || secrets.nftStorageApiKey == undefined) {
  throw Error("NFT_STORAGE_API_KEY NOT SET")
}

const BASE_URL = "https://api.thenextleg.io/v2"
const AUTH_TOKEN = secrets.midjourneyApiKey
const AUTH_HEADERS = {
  Authorization: `Bearer ${AUTH_TOKEN}`,
  "Content-Type": "application/json",
}

const type = args[0]
if (type == "NEW_BORN") {
  const prompt = args[1]
  const rarityNumber = args[2]

  const rarity = getRarity(rarityNumber)

  const modifiedPrompt = `${prompt}. The background and theme must be ${rarity.color}`

  const outputsResponse = await Functions.makeHttpRequest({
    url: `${BASE_URL}/imagine`,
    method: "POST",
    headers: AUTH_HEADERS,
    data: {
      msg: modifiedPrompt,
    },
  })

  console.log(outputsResponse)

  if (outputsResponse.data == undefined && outputsResponse.error == undefined) {
    throw Error("Invalid query")
  }

  if (outputsResponse.error || outputsResponse.data.success == false) {
    throw Error("API Failed")
  }

  const messageId = outputsResponse.data.messageId

  return Functions.encodeString(messageId)
} else {
  const nft1TokenURI = args[1]
  const nft2TokenURI = args[2]
  const rarityNumber = args[3]

  const nft1MetadataRequest = Functions.makeHttpRequest({
    url: nft1TokenURI,
    method: "GET",
    headers: { "Content-Type": "application/json" },
  })

  const nft2MetadataRequest = Functions.makeHttpRequest({
    url: nft2TokenURI,
    method: "GET",
    headers: { "Content-Type": "application/json" },
  })

  const [nft1MetadataResponse, nft2MetadataResponse] = await Promise.all([nft1MetadataRequest, nft2MetadataRequest])

  if (nft1MetadataResponse.error) {
    throw Error("NFT1 Metadata Fetch Failed")
  }

  if (nft2MetadataResponse.error) {
    throw Error("NFT2 Metadata Fetch Failed")
  }

  const nft1Metadata = nft1MetadataResponse.data
  const nft2Metadata = nft2MetadataResponse.data

  const rarity = getRarity(rarityNumber)

  const modifiedPrompt = `${nft1Metadata.image} ${nft2Metadata.image}. The background and theme must be ${rarity.color}`

  const outputsResponse = await Functions.makeHttpRequest({
    url: `${BASE_URL}/imagine`,
    method: "POST",
    headers: AUTH_HEADERS,
    data: {
      msg: modifiedPrompt,
    },
  })

  if (outputsResponse.data == undefined && outputsResponse.error == undefined) {
    throw Error("Invalid query")
  }
  if (outputsResponse.error || outputsResponse.data.success == false) {
    throw Error("API failed")
  }

  const messageId = outputsResponse.data.messageId

  return Functions.encodeString(messageId)
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
