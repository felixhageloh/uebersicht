'use strict';

const ws = require('./SharedSocket');

module.exports = function dispatch(eventType, payload) {
  ws.send(
    JSON.stringify({type: eventType, payload: payload})
  );
};
