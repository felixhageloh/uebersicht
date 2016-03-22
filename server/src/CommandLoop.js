const runCommand = require('./runCommand');

function scheduleTick(tick, refreshFrequency) {
  if (refreshFrequency !== false) {
    return setTimeout(tick, refreshFrequency);
  }
}

module.exports = function CommandLoop(command, refreshFrequency) {
  const api = {};
  const callbacks = [];
  let started = false;
  let timer;

  function loop() {
    if (!command) {
      return;
    }

    clearTimeout(timer);
    runCommand(command, (error, output) => {
      if (started) {
        callbacks.forEach(c => c(error, output));
        timer = scheduleTick(loop, refreshFrequency);
      }
    })
    .timeout(refreshFrequency);
  }

  api.start = function start() {
    if (!started) {
      started = true;
      loop();
    }
    return api;
  };

  api.stop = function stop() {
    if (started) {
      started = false;
      clearTimeout(timer);
    }
    return api;
  };

  api.map = function map(callback) {
    callbacks.push(callback);
    return api;
  };

  api.forceTick = function tick() {
    runCommand(command, (error, output) => {
      callbacks.forEach(c => c(error, output));
    });
    return api;
  };

  return api.start();
};
