'use strict';

const $ = require('jquery');
window.jQuery = $;

const Timer = require('./Timer');
const runCommand = require('./runCommand');
const runShellCommand = require('./runShellCommand');

const defaults = {
  id: 'widget',
  refreshFrequency: 1000,
  render: (output) => output,
  afterRender: () => {},
};

// This is a wrapper (something like a base class), around the
// specific implementation of a widget.
module.exports = function ClassicWidget(widgetObject) {
  const api = {};
  const internalApi = {};

  let el = null;
  let contentEl = null;
  let rendered = false;
  let commandLoop = null;
  let implementation = {};
  let currentError = null;

  const init = (widget) => {
    currentError = widget.error ? JSON.parse(widget.error) : null;
    implementation = widget.implementation || {};

    for (const [k, v] of Object.entries(defaults)) {
      if (implementation[k] == null) implementation[k] = v;
    }
    for (const [k, v] of Object.entries(internalApi)) {
      if (!implementation[k]) implementation[k] = v;
    }

    commandLoop = Timer().map((done) =>
      runCommand(implementation, (err, output) => {
        redraw(err, output);
        done(implementation.refreshFrequency);
      }));

    return api;
  };

  // renders and returns the widget's dom element
  api.create = () => {
    el = document.createElement('div');
    contentEl = document.createElement('div');
    contentEl.id = implementation.id;
    contentEl.className = 'widget';
    el.innerHTML = `<style>${implementation.css}</style>\n`;
    el.appendChild(contentEl);

    start();
    return el;
  };

  api.destroy = () => {
    stop();
    if (!el) return;
    if (el.parentNode) el.parentNode.removeChild(el);
    el = null;
    contentEl = null;
    rendered = false;
  };

  api.update = (newImplementation) => {
    const parentEl = el.parentNode;
    api.destroy();
    init(newImplementation);
    parentEl.appendChild(api.create());
  };

  api.domEl = () => el;

  api.isRendered = () => !!el;

  api.internalApi = () => internalApi;

  api.implementation = () => implementation;

  api.forceRefresh = () => internalApi.refresh();

  // starts the widget refresh cycle
  const start = () => {
    if (currentError) return redraw(currentError);
    commandLoop.start();
  };
  internalApi.start = start;

  // stops the widget refresh cycle
  const stop = () => commandLoop.stop();
  internalApi.stop = stop;

  // run widget command and redraw the widget
  const refresh = () => {
    if (implementation.command == null) return redraw();
    commandLoop.forceTick();
  };
  internalApi.refresh = refresh;

  // runs command in the shell and calls callback with the result (err, stdout)
  const run = (command, callback) => runShellCommand(command, callback);
  internalApi.run = run;

  const redraw = (error, output) => {
    if (error) {
      contentEl.style.fontFamily = 'monospace';
      contentEl.style.fontSize = '12px';
      contentEl.style.whiteSpace = 'pre';
      contentEl.style.background = '#fff';
      contentEl.style.padding = '20px';
      contentEl.innerHTML = error.message + '\n' + (error.lines || '');
      console.error(`${implementation.id}:`, error);
      rendered = false;
      return;
    } else {
      contentEl.style.fontFamily = '';
      contentEl.style.fontSize = '';
      contentEl.style.whiteSpace = '';
      contentEl.style.background = '';
      contentEl.style.padding = '';
    }

    try {
      renderOutput(output);
    } catch (e) {
      redraw(e);
    }
  };

  const renderOutput = (output) => {
    if (implementation.update != null && rendered) {
      implementation.update(output, contentEl);
    } else {
      contentEl.innerHTML = implementation.render(output);
      loadScripts(contentEl);

      implementation.afterRender(contentEl);
      rendered = true;
      if (implementation.update != null) implementation.update(output, contentEl);
    }
  };

  // getElementsByTagName returns a *live* collection, and this loop
  // replaces each node as it iterates -- snapshot into a real array
  // first so replacing doesn't shift indices out from under us.
  const loadScripts = (domEl) => {
    for (const script of Array.from(domEl.getElementsByTagName('script'))) {
      const s = document.createElement('script');
      s.src = script.src;
      domEl.replaceChild(s, script);
    }
  };

  return init(widgetObject);
};
