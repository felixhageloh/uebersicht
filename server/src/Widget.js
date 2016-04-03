var ClassicWidget = require('./ClassicWidget.coffee');
var VirtualDomWidget = require('./VirtualDomWidget');
const html = require('snabbdom-jsx').html;

module.exports = function Widget(widget) {
  var api;
  var implementation = eval(widget.body)(widget.id);

  if (/\.jsx$/.test(widget.filePath)) {
    api = VirtualDomWidget(implementation);
  } else {
    api = ClassicWidget(implementation);
  }

  var updateSub = api.update;
  api.update = function update(newSource) {
    updateSub(eval(newSource)(widget.id));
  };

  return api;
};
