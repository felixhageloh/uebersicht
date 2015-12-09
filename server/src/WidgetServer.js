// REST api for individual widgets
// Listens to /widget

module.exports = function WidgetServer(widgetsController) {
  const handlers = {
    put(id, data) {
      widgetsController.updateWidget(id, data);
      return 200;
    }
  };

  function handleRequest(req, id, verb, callback) {
    const handler = handlers[verb];
    if (!handler) {
      return callback(400);
    }

    getJsonBody(req, (err, body) => {
      var code;
      if (err) {
        console.log(err);
        code = 500;
      } else {
        code = handler(id, body);
      }

      callback(code);
    });
  }

  return function WidgetServerMiddleWare(req, res, next) {
    const parts = req.url.replace(/^\//, '').split('/');

    if (parts[0] !== 'widget') {
      return next();
    }

    const verb = req.method.toLowerCase();
    const id = parts[1].trim();

    handleRequest(req, id, verb, (statusCode) => {
      res.statusCode = statusCode;
      res.end();
    });
  };
};

function getJsonBody(req, callback) {
  var data = '';
  req.on('data', (chunk) => data += chunk.toString());
  req.on('end', () => {
    try {
      json = JSON.parse(data) || {};
      callback(null, json);
    } catch (e) {
      callback(e);
    }
  });
}
