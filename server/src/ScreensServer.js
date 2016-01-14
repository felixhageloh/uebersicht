// middleware to serve all screens as json.
// Listens to /screens

module.exports = function(screensStore) {
  return function ScreensServer(req, res, next) {
    if (req.url === '/screens/') {
      res.end(
        JSON.stringify({screens: screensStore.screens()})
      );
    } else {
      next();
    }
  };
};


