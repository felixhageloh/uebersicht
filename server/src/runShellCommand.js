const post = require('superagent').post;

function wrapError(err, res) {
  return err
    ? new Error((res || {}).text || 'error running command')
    : null
    ;
}

module.exports = function runShellCommand(command, callback) {
  const request = post('/run/').send(command);
  return callback
    ? request.end((err, res) => callback(wrapError(err, res), (res || {}).text))
    : request
      .catch(err => { throw wrapError(err, err.response); })
      .then(res => res.text)
    ;
};
