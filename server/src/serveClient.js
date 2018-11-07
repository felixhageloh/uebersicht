'use strict';

const fs = require('fs');
const path = require('path');
const stream = require('stream');

module.exports = (publicDir) => {
  const indexHTML = fs.readFileSync(path.join(publicDir, 'index.html'));
  return function serveClient(req, res, next) {
    const bufferStream = new stream.PassThrough();
    bufferStream.pipe(res);
    bufferStream.end(indexHTML);
  };
};
