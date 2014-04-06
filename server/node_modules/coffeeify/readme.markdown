# coffeeify

browserify v2 plugin for coffee-script

mix and match `.coffee` and `.js` files in the same project

[![Build Status](https://travis-ci.org/jnordberg/coffeeify.png?branch=master)](https://travis-ci.org/jnordberg/coffeeify)

# example

given some files written in a mix of `js` and `coffee`:

foo.coffee:

``` coffee
console.log(require './bar.js')
```

bar.js:

``` js
module.exports = require('./baz.coffee')(5)
```

baz.coffee:

``` js
module.exports = (n) -> n * 111
```

install coffeeify into your app:

```
$ npm install coffeeify
```

when you compile your app, just pass `-t coffeeify` to browserify:

```
$ browserify -t coffeeify foo.coffee > bundle.js
$ node bundle.js
555
```

you can omit the `.coffee` extension from your requires if you add the extension to browserify's module extensions:

``` js
module.exports = require('./baz')(5)
```

```
$ browserify -t coffeeify --extension=coffee foo.coffee > bundle.js
$ node bundle.js
555
```

# install

With [npm](https://npmjs.org) do:

```
npm install coffeeify
```

# license

MIT
