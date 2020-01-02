module.exports = (containerEl) => {
  let insideWidget = false;

  const checkHover = (e) => {
    if (insideWidget && containerEl === e.target) {
      insideWidget = false;
      window.webkit.messageHandlers.uebersicht.postMessage('widgetLeave');
    } else if (!insideWidget && containerEl !== e.target) {
      insideWidget = true;
      window.webkit.messageHandlers.uebersicht.postMessage('widgetEnter');
    }
  };

  const checkHoverRecursive = () => {
    window.addEventListener(
      'mousemove',
      (e) => {
        checkHover(e);
        setTimeout(checkHoverRecursive, 32);
      },
      {once: true},
    );
  };

  checkHoverRecursive();
};
