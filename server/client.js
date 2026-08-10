'use strict';

const redux = require('redux');
window.$ = require('jquery');

const reducer = require('./src/reducer');
const listenToRemote = require('./src/listen');
const sharedSocket = require('./src/SharedSocket');
const render = require('./src/render');
const actions = require('./src/actions');
const detectWidgetHover = require('./src/detectWidgetHover');
let userCssLink = null;

window.onload = () => {
  sharedSocket.open(`ws://${window.location.host}`);
  const path = window.location.pathname.split('/');
  const screen = {
    id: Number(path[1]),
    layer: path[2],
  };
  const contentEl = document.getElementById('uebersicht');
  contentEl.innerHTML = '';
  userCssLink = Array.from(document.querySelectorAll('link'))
    .find((el) => el.href.match('userMain.css'));

  detectWidgetHover(contentEl);

  getState((err, initialState) => {
    if (err != null) bail(err, 10000);
    const store = redux.createStore(reducer, initialState);
    Object.keys(initialState.widgets).forEach((id) =>
      fetchWidget(id).then((widgetImpl) => store.dispatch(actions.showWidget(id, widgetImpl))));

    let prevState = null;
    store.subscribe(() => {
      const nextState = store.getState();
      if (nextState === prevState) return;
      render(store.getState(), screen, contentEl, store.dispatch);
      prevState = nextState;
    });

    listenToRemote((action) => {
      if (action.type === 'WIDGET_WANTS_REFRESH') {
        render.rendered[action.payload]?.instance?.forceRefresh();
      } else if (action.type === 'WIDGET_ADDED') {
        store.dispatch(action);
        if (action.payload.error) return;
        fetchWidget(action.payload.id)
          .then((widgetImpl) => store.dispatch(actions.showWidget(action.payload.id, widgetImpl)));
      } else if (action.type === 'MASTER_STYLE_CHANGED') {
        reloadUserCSS();
      } else {
        store.dispatch(action);
      }
    });
    render(initialState, screen, contentEl, store.dispatch);
  });
};

// legacy
window.uebersicht = {
  makeBgSlice: (canvas) => {
    console.warn(
      'makeBgSlice has been deprecated. Please use CSS ' +
      'backdrop-filter instead: ' +
      'https://developer.mozilla.org/en-US/docs/Web/CSS/backdrop-filter',
    );
  },
};

window.addEventListener('contextmenu', (e) => e.preventDefault());

const getState = (callback) =>
  $.get('/state/')
    .done((response) => callback(null, JSON.parse(response)))
    // NOTE: `response` here is not in scope (this callback takes none) --
    // faithfully preserved from the original CoffeeScript, which had the
    // same bug (`.fail -> callback response, null`). If /state/ ever
    // actually fails to load, this throws a ReferenceError instead of
    // calling back with an error. Flagged, not fixed, as out of scope
    // for a mechanical decaffeination pass.
    .fail(() => callback(response, null));

const fetchWidget = (id) => new Promise((resolve, reject) => {
  const scriptTag = document.createElement('SCRIPT');
  scriptTag.id = id;
  scriptTag.src = '/widgets/' + id;
  scriptTag.onload = () => {
    document.head.removeChild(scriptTag);
    resolve(require(id));
  };
  scriptTag.onerror = (err) => {
    document.head.removeChild(scriptTag);
    reject(err);
  };
  document.head.appendChild(scriptTag);
});

const reloadUserCSS = () => {
  const href = userCssLink.href.split('?')[0];
  userCssLink.href = `${href}?${new Date().getTime()}`;
};

const bail = (err, timeout = 0) => {
  if (err != null) console.log(err);
  setTimeout(() => window.location.reload(true), timeout);
};
