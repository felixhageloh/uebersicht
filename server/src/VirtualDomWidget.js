var main = require('./mainLoop');
var snabbdom = require('snabbdom');
var $ = require('jquery');
var html = require('snabbdom-jsx').html;

var patch = snabbdom.init([
  require('snabbdom/modules/class'),
  require('snabbdom/modules/props'),
  require('snabbdom/modules/style'),
  require('snabbdom/modules/eventlisteners'),
]);

var defaults = {
  id: 'widget',
  refreshFrequency: 1000,
  render: function render(props) {
    return html('div', null, props.output);
  },
};

module.exports = function VirtualDomWidget(implementationString) {
  var api = {};
  var contentEl;
  var loop;
  var started = false;
  var timer;
  var implementation = {};


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

  function start() {
    if (!started) {
      started = true;
      clearTimeout(timer);
      refresh();
    }
  }

  function stop() {
    if (started) {
      started = false;
      clearTimeout(timer);
    }
  }

  function refresh() {
    if (!implementation.command) {
      return;
    }

    clearTimeout(timer);

    var request = run(implementation.command, function(err, output) {
      loop.update({output: output, error: err});
    });

    request.always(function() {
      if (started && implementation.refreshFrequency !== false) {
        timer = setTimeout(refresh, implementation.refreshFrequency);
      }
    });
  }

  function run(command, callback) {
    return $.ajax({
      url: '/run/',
      method: 'POST',
      data: command,
      timeout: implementation.refreshFrequency,
      error: function(xhr) {
        callback(xhr.responseText || 'error running command');
      },
      success: function(output) {
        callback(null, output);
      },
    });
  }

  api.render = function render() {
    contentEl = document.createElement('div');
    contentEl.id = implementation.id;
    contentEl.className = 'widget';

    loop = main(
      { output: '', error: null },
      implementation.render.bind(implementation),
      patch,
      contentEl
    );

    start();

    return contentEl;
  };

  api.destroy = function destroy() {
    stop();
    if (contentEl && contentEl.parentNode) {
      contentEl.parentNode.removeChild(contentEl);
    }
    contentEl = null;
  };

  return init();
};
