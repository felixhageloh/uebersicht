'use strict';

// middleware to serve the results of shell commands
// Listens to POST /run/
const {spawn} = require('child_process');

module.exports = function (workingDir, useLoginShell) {
  const args = useLoginShell ? ['-l'] : [];

  // the Connect middleware
  return function (req, res, next) {
    if (req.method !== 'POST' || req.url !== '/run/') return next();
    const shell = spawn('bash', args, {cwd: workingDir});

    req.on('data', (chunk) => shell.stdin.write(chunk));

    req.on('end', () => {
      let setStatusOnce = (status) => {
        res.writeHead(status);
        setStatusOnce = () => {};
      };

      shell.stderr.on('data', (d) => {
        setStatusOnce(500);
        res.write(d);
      });

      shell.stdout.on('data', (d) => {
        setStatusOnce(200);
        res.write(d);
      });

      shell.on('error', (err) => {
        setStatusOnce(500);
        res.write(err.message);
      });

      shell.on('close', () => {
        setStatusOnce(200);
        res.end();
      });

      shell.stdin.write('\n');
      shell.stdin.end();
    });
  };
};
