exports.handler = async (event) => {
    const response = {
        statusCode: 200,
        body: JSON.stringify('Hello with feature-1-v1'),
    }
    return response
}
