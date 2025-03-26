module.exports = function ensureSameHost(host) {
    return ((req, res, next) => {
        if (req.headers.host && req.headers.host === host) {
            return next()
        }
        res.writeHead(400)
        res.end()
    })
}
