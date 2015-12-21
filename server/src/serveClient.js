'use strict';

const fs = require('fs');
const path = require('path');
const stream = require('stream');

const indexHTML = fs.readFileSync(
  path.resolve(
    __dirname,
    path.join('public', 'index.html')
  )
);

module.exports = function serveClient(req, res, next) {
  const bufferStream = new stream.PassThrough();
  bufferStream.pipe(res);
  bufferStream.end(indexHTML);
};
