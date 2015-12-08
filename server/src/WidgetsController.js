module.exports = function WidgetsController(widgetDir, settingsPath) {
  const api = {};

  api.widgets = function widgets() {
    return widgetDir.widgets();
  }

  return api;
}
