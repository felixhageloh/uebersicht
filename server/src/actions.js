'use strict';

function addWidget(widget) {
  const {id, filePath, error, mtime} = widget;
  return {
    type: 'WIDGET_ADDED',
    payload: {id, filePath, error, mtime},
  };
}

exports.showWidget = function showWidget(id, impl) {
  return {
    type: 'WIDGET_LOADED',
    id: id,
    payload: impl,
  };
};

function removeWidget(id) {
  return {
    type: 'WIDGET_REMOVED',
    payload: id,
  };
}

exports.applyWidgetSettings = function applyWidgetSettings(id, settings) {
  return {
    type: 'WIDGET_SETTINGS_CHANGED',
    payload: { id: id, settings: settings },
  };
};

exports.get = function(widgetEvent) {
  switch (widgetEvent.type) {
    case 'added': return addWidget(widgetEvent.widget);
    case 'removed': return removeWidget(widgetEvent.id);
  };
};
