module.exports = function ensureSameOrgin(origin) {
  const fromSameOrigin = (req) => {
    return req.method == 'GET' ||
      (req.headers.origin && req.headers.origin === origin);
  }

  return ((req, res, next) => {
    if (fromSameOrigin(req)) return next();
    res.writeHead(403);
    res.end();
  })
}
