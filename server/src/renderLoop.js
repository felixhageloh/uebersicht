var raf = require('raf');

module.exports = function RenderLoop(initialState, render) {
  var currentState = null;
  var redrawScheduled = false;
  var inRenderingTransaction = false;

  var loop = {
    state: initialState,
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
    try {
      render(currentState);
    } catch (err) {
      console.error(err);
    }
    inRenderingTransaction = false;
    currentState = null;
  }

  return update(initialState);
};
