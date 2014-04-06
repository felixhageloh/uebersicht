var fake_module = require('./fake_module');

var bar = function () {
    return fake_module.foo();
};

exports.bar = bar;
