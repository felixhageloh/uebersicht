const RenderLoop = require('./RenderLoop');
const CommandLoop = require('./CommandLoop');
const snabbdom = require('snabbdom');
const html = require('snabbdom-jsx').html;

const patch = snabbdom.init([
  require('snabbdom/modules/class'),
  require('snabbdom/modules/props'),
  require('snabbdom/modules/style'),
  require('snabbdom/modules/eventlisteners'),
]);

const defaults = {
  id: 'widget',
  refreshFrequency: 1000,
  render: function render(props) {
    return html('div', null, props.output);
  },
};

module.exports = function VirtualDomWidget(implementationString) {
  const api = {};
  const implementation = {};
  let contentEl;
  let commandLoop;
  let renderLoop;

  function init() {
    (new Function('exports', 'html', implementationString))(
      implementation,
      html
    );

    for (var k in defaults) {
      if (implementation[k] === undefined || implementation[k] === null) {
        implementation[k] = defaults[k];
      }
    }

    return api;
  }

  api.create = function render() {
    contentEl = document.createElement('div');
    contentEl.id = implementation.id;
    contentEl.className = 'widget';

    renderLoop = RenderLoop(
      { output: '', error: null },
      implementation.render.bind(implementation),
      patch,
      contentEl
    );

    commandLoop = CommandLoop(
      implementation.command,
      implementation.refreshFrequency
    ).map((err, output) => renderLoop.update({ error: err, output: output }));

    return contentEl;
  };

  api.destroy = function destroy() {
    commandLoop.stop();
    if (contentEl && contentEl.parentNode) {
      contentEl.parentNode.removeChild(contentEl);
    }
    contentEl = null;
  };

  return init();
};
