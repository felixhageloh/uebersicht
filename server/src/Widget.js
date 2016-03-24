var ClassicWidget = require('./ClassicWidget.coffee');
var VirtualDomWidget = require('./VirtualDomWidget');

module.exports = function Widget(widget) {
  var instance;
  if (/\.jsx$/.test(widget.filePath)) {
    instance = VirtualDomWidget(widget.body);
  } else {
    instance = ClassicWidget(widget.body);
  }

  return instance;
};
