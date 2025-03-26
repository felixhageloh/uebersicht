const fs = require('fs');
const path = require('path');
const urls = require('url');

module.exports = (widgetsDir) => (req, res, next) => {
  const url = urls.parse(req.url);
  if (url.pathname !== '/userMain.css') return next();

  fs.ReadStream(path.join(widgetsDir, 'main.css'))
    .on('error', (err) => {
      if (err.code !== 'ENOENT') throw err;
      res.end('');
    })
    .pipe(res);
};
