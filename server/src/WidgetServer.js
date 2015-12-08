// REST api for individual widgets
// Listens to /widget

module.exports = function WidgetServer(widgetsController) {
  const handle = {
    put(id, data) {
      console.log(id, data);
      return 200;
    }
  };

  return function WidgetServerMiddleWare(req, res, next) {
    const parts = req.url.replace(/^\//, '').split('/');

    if (parts[0] !== 'widget') {
      return next();
    }

    const verb = req.method.toLowerCase();
    const id = parts[1].trim();
    const data = {};

    const handler = handle[verb];
    if (handler) {
      res.statusCode = handler(id, data);
    } else {
      res.statusCode = 400;
    }

    res.end();
  };
};
