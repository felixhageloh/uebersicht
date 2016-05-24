const RenderLoop = require('./RenderLoop');
const Timer = require('./Timer');
const runCommand = require('./runCommand');
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
  init: function init() {},
  render: function render(props) {
    return html('div', null, props.output);
  },
  updateProps: function updateProps(props, action) {
    if (action.type === 'UB/COMMAND_RAN') {
      return { error: action.error, output: action.output };
    } else {
      return props;
    }
  },
  initialProps: { output: '', error: null },
};

module.exports = function VirtualDomWidget(widgetObject) {
  const api = {};
  let implementation;
  let wrapperEl;
  let commandLoop;
  let renderLoop;

  function init(widget) {
    implementation = eval(widget.body)(widget.id);
    implementation.id = widget.id;

    for (var k in defaults) {
      if (implementation[k] === undefined ||
          implementation[k] === null) {
        implementation[k] = defaults[k];
      }
    }

    return api;
  }

  function start() {
    implementation.init();
    commandLoop = Timer()
      .map((done) => {
        runCommand(implementation, (err, output) => {
          dispatch({ type: 'UB/COMMAND_RAN', error: err, output: output });
          done(implementation.refreshFrequency);
        });
      })
      .start();
  }

  function dispatch(action) {
    renderLoop.update(
      implementation.updateProps(renderLoop.state, action)
    );
  }

  function render(state) {
    try {
      return implementation.render(state, dispatch);
    } catch (e) {
      console.error(e);
      return html('div', {}, e.message);
    }
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
