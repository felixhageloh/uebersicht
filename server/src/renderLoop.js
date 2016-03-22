var raf = require('raf');

module.exports = function RenderLoop(initialState, render, patch, target) {
  var currentState = null;
  var oldNode = target;
  var redrawScheduled = false;
  var inRenderingTransaction = false;

  var loop = {
    state: initialState,
    target: target,
    update: update,
  };

  function update(state) {
    if (inRenderingTransaction) {
      throw Error("can't update while rendering");
    }

    if (currentState === null && !redrawScheduled) {
      redrawScheduled = true;
      raf(redraw);
    }

    currentState = state;
    loop.state = currentState;
    return loop;
  }

  function redraw() {
    redrawScheduled = false;
    if (currentState === null) {
      return;
    }

    inRenderingTransaction = true;
    var newNode = render(currentState);
    inRenderingTransaction = false;

    oldNode = patch(oldNode, newNode);
    currentState = null;
  }

  return update(initialState);
};
