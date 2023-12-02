if (secrets.midjourneyApiKey == "" || secrets.midjourneyApiKey == undefined) {
  throw Error("MIDJOURNEY_API_KEY NOT SET")
}

const BASE_URL = "https://api.thenextleg.io/v2"
const AUTH_TOKEN = secrets.midjourneyApiKey
const AUTH_HEADERS = {
  Authorization: `Bearer ${AUTH_TOKEN}`,
  "Content-Type": "application/json",
}

// Arguments
const prompt = args[1]
const randomness = args[2]
const seed = args[3]
/**
 * A function to pause for a given amount of time
 */
function sleep(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds))
}

/**
 * Continue polling a generation an image is completed, or fails.
 * You can also use a webhook to get notified when the image is ready.
 * It will contain the same response body as seen here.
 */
const fetchToCompletion = async (messageId, retryCount, maxRetry = 20) => {
  const imageRes = await Functions.makeHttpRequest({
    url: `${BASE_URL}/message/${messageId}`,
    method: "GET",
    headers: AUTH_HEADERS,
  })
  console.log(imageRes)
  const imageResponseData = imageRes.data
  console.log(imageResponseData)
  if (imageResponseData.progress === 100) {
    return imageResponseData
  }

  if (imageResponseData.progress === "incomplete") {
    throw new Error("Image generation failed")
  }

  if (retryCount > maxRetry) {
    throw new Error("Max retries exceeded")
  }

  if (imageResponseData.progress && imageResponseData.progressImageUrl) {
    console.log("---------------------")
    console.log(`Progress: ${imageResponseData.progress}%`)
    console.log(`Progress Image Url: ${imageResponseData.progressImageUrl}`)
    console.log("---------------------")
  }

  await sleep(5000)
  return fetchToCompletion(messageId, retryCount + 1)
}

const completedImageData = await fetchToCompletion(seed, 0)

console.log("\n=====================")
console.log("COMPLETED IMAGE DATA")
console.log(completedImageData)
console.log("=====================")

return Functions.encodeString("DONE")
