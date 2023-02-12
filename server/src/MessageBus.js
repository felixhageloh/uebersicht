const cookieParser = require('cookie-parser');
const WebSocket = require('ws');
const parseCookies = cookieParser();

module.exports = function MessageBus({
  server,
  allowedHost,
  allowedOrigin,
  authenticationToken,
}) {
  const isHostAllowed = (req) =>
    allowedHost ? req.headers.host === allowedHost : true;

  const isOriginAllowed = (origin) =>
    allowedOrigin ? origin === allowedOrigin || origin === 'Übersicht' : true;

  const isRequestAuthenticated = (req) => {
    parseCookies(req, null, () => {});
    return authenticationToken
      ? req.cookies.token === authenticationToken
      : true;
  };

  const verifyClient = ({req, origin}) => {
    if (!isHostAllowed(req)) return false;
    if (!isOriginAllowed(origin)) return false;
    return isRequestAuthenticated(req);
  };

  const wss = new WebSocket.Server({server, verifyClient});

  function broadcast(data) {
    wss.clients.forEach((client) => {
      if (client.readyState === WebSocket.OPEN) {
        client.send(data);
      }
    });
  }

  wss.on('connection', function connection(ws) {
    ws.on('message', broadcast);
  });

  wss.on('error', function handleError(err) {
    console.error(err);
  });

  return wss;
};
