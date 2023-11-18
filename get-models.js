const response = await Functions.makeHttpRequest({
  url: `https://api.stablecog.com/v1/image/generation/models`,
  method: "GET",
  headers: {
    "Access-Control-Allow-Origin": "*",
    "Content-Type": "application/json",
  },
})
console.log(JSON.stringify(response))
if (response.error) {
  return Functions.encodeString(response.message)
} else {
  return Functions.encodeString(response.data)
}
