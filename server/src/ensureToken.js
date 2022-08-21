var validateTokenCookie = require('./validateTokenCookie')

module.exports = function ensureToken(token, disabled) {
  return ((req, res, next) => {
    if (disabled) {
      return next()
    }

    if (!validateTokenCookie(token, req.headers.cookie)) {
      res.writeHead(403)
      res.end()
      return
    }

    return next()
  })
}
