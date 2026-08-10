var ClassicWidget = require('./ClassicWidget');
var VirtualDomWidget = require('./VirtualDomWidget');

module.exports = function Widget(widget) {
  var api;

  if (/\.jsx$/.test(widget.filePath)) {
    api = VirtualDomWidget(widget);
  } else {
    api = ClassicWidget(widget);
  }

  return api;
};
