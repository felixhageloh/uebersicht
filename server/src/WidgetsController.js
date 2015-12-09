module.exports = function WidgetsController(widgetDir, settingsPath) {
  const api = {};
  const settings = {};
  const trigger = {
    change() {}
  };

  api.init = function init(callbacks) {
    Object.assign(trigger, callbacks);
    widgetDir.watch((changes) => trigger.change(changes));
  };

  api.widgets = function widgets() {
    const allWidgets = widgetDir.widgets();
    const widgetsForScreen = {};

    Object.keys(allWidgets).forEach((id) => {
      var widgetSettings = settings[id] || {};
      if (!widgetSettings.hidden) {
        widgetsForScreen[id] = allWidgets[id];
      }
    });

    return widgetsForScreen;
  };

  api.updateWidget = function updateWidget(id, data) {
    settings[id] = Object.assign(
      settings[id] || {},
      data
    );

    if (settings[id].hidden) {
      trigger.change({ [id]: 'deleted' });
    } else {
      trigger.change({ [id]: widgetDir.get(id) });
    }
  };

  return api;
};
