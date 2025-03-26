'use strict';

function validateHasCommand(impl, issues, message) {
  if (impl.refreshFrequency === false) {
    return;
  }

  if (typeof impl.command !== 'string' && impl.command !== 'function') {
    issues.push(message);
  }
}

module.exports = function validateWidget(impl) {
  const issues = [];

  if (impl) {
    validateHasCommand(impl, issues, 'no command given');
  } else {
    issues.push('empty implementation');
  }

  return issues;
};
