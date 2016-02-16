'use strict';

exports.addWidget = function widgetLoaded(widget) {
  return {
    type: 'WIDGET_ADDED',
    payload: widget,
  };
};

exports.removeWidget = function removeWidget(id) {
  return {
    type: 'WIDGET_REMOVED',
    payload: id,
  };
};

exports.applyWidgetSettings = function applyWidgetSettings(id, settings) {
  return {
    type: 'WIDGET_SETTINGS_CHANGED',
    payload: { id: id, settings: settings },
  };
};
