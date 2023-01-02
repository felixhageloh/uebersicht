module.exports = function authenticateRequest(token) {
    return ((req, res, next) => {
        if (req.cookies.token === token) {
            return next()
        }
        res.writeHead(400)
        res.end()
    })
}
