'use strict';

// middleware to serve the current state
module.exports = (store) => (req, res, next) => {
  if (req.url === '/state/') {
    res.end(JSON.stringify(store.getState()));
  } else {
    next();
  }
};
