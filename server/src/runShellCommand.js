const post = require('superagent').post;

module.exports = function runShellCommand(command, callback) {
  return post('/run/')
    .send(command)
    .end((err, res) => {
      if (callback) {
        const error = err ? res.text || 'error running command' : null;
        const output = res.text;
        callback(error, output);
      }
    });
};
