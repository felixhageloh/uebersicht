module.exports = function validateTokenCookie(token, cookieStr) {
  if (!cookieStr) {
    return false
  }

  const cookies = cookieStr
    .split(';')
    .map(x => x.split(/=(.*)$/s))
    .reduce((x, y) => {
      x[decodeURIComponent(y[0].trim())] = decodeURIComponent(y[1].trim())
      return x
    }, {})

  if (!cookies.token || cookies.token !== token) {
    return false
  }

  return true
}
