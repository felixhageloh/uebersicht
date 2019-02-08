const post = require("superagent").post;

function wrapError(err, res) {
  if (err) console.log("wrap", err.name, err.message);
  return err ? new Error((res || {}).text || "error running command") : null;
}

function isKeepAliveError(err) {
  return err && err.message.indexOf("Request has been terminated") === 0;
}

module.exports = function runShellCommand(command, callback) {
  const request = post("/run/")
    .retry(2, isKeepAliveError)
    .send(command);
  return callback
    ? request.end((err, res) => callback(wrapError(err, res), (res || {}).text))
    : request
        .catch(err => {
          throw wrapError(err, err.response);
        })
        .then(res => res.text);
};
