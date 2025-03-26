function scheduleTick(tick, duration) {
  if (duration !== false) {
    return setTimeout(tick, duration);
  }
}

module.exports = function Timer() {
  const api = {};
  let callback = (done) => done();
  let started = false;
  let timer;

  function loop() {
    clearTimeout(timer);
    if (started) {
      callback((nextTickDuration) => {
        timer = scheduleTick(loop, nextTickDuration);
      });
    }
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

  api.map = function map(cb) {
    callback = cb;
    return api;
  };

  api.forceTick = function tick() {
    callback(() => {});
    return api;
  };

  return api;
};
