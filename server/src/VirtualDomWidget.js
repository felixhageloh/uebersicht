const RenderLoop = require('./RenderLoop');
const CommandLoop = require('./CommandLoop');
const snabbdom = require('snabbdom');

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
  outputToProps: function outputToProps(err, output) {
    return { error: err, output: output };
  },
  initialProps: { output: '', error: null },
};

module.exports = function VirtualDomWidget(widgetObject) {
  const api = {};
  let implementation;
  let wrapperEl;
  let commandLoop;
  let renderLoop;

  function init(newImplementation) {
    implementation = newImplementation;
    for (var k in defaults) {
      if (implementation[k] === undefined ||
          implementation[k] === null) {
        implementation[k] = defaults[k];
      }
    }

    return api;
  }

  function start() {
    commandLoop = CommandLoop(
      implementation.command,
      implementation.refreshFrequency
    ).map((err, output) => {
      renderLoop.update(
        implementation.outputToProps(err, output, renderLoop.state)
      );
    });
  }

  function render(state) {
    return implementation.render(state);
  }

  api.create = function create() {
    const contentEl = document.createElement('div');
    wrapperEl = document.createElement('div');
    wrapperEl.id = implementation.id;
    wrapperEl.className = 'widget';
    wrapperEl.appendChild(contentEl);
    document.body.appendChild(wrapperEl);

    renderLoop = RenderLoop(
      implementation.initialProps,
      render,
      patch,
      contentEl
    );

    start();
    return wrapperEl;
  };

  api.destroy = function destroy() {
    commandLoop.stop();
    if (wrapperEl && wrapperEl.parentNode) {
      wrapperEl.parentNode.removeChild(wrapperEl);
    }
    renderLoop = null;
    wrapperEl = null;
  };

  api.update = function update(newImplementation) {
    commandLoop.stop();
    init(newImplementation);
    renderLoop.update(renderLoop.state); // force redraw
    start();
  };

  return init(widgetObject);
};
