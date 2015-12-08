node-tosource
=============
toSource is a super simple function that converts JavaScript objects back to source code.

Introduction
------------
Motivation: JSON doesn't support serializing functions, dates, or regular expressions. I wanted
a quick and simple way to push trusted data structures with code from Node down to the browser.

This should make it easier to share code and modules between the server and client.

Installation
------------

```
npm install tosource
```

Examples
--------
The following code:

```js
var toSource = require('tosource')
console.log(toSource(
    [ 4, 5, 6, "hello", {
        a:2,
        'b':3,
        '1':4,
        'if':5,
        yes:true,
        no:false,
        nan:NaN,
        infinity:Infinity,
        'undefined':undefined,
        'null':null,
        foo: function(bar) {
            console.log("woo! a is "+a)
            console.log("and bar is "+bar)
        }
    },
    /we$/gi,
    new Date("Wed, 09 Aug 1995 00:00:00 GMT")]
))
```

Output:

```js
[ 4,
  5,
  6,
  "hello",
  { "1":4,
    a:2,
    b:3,
    "if":5,
    yes:true,
    no:false,
    nan:NaN,
    infinity:Infinity,
    "undefined":undefined,
    "null":null,
    foo:function (bar) {
            console.log("woo! a is "+a)
            console.log("and bar is "+bar)
        } },
  /we$/gi,
  new Date(807926400000) ]
```


See [test.js][1] for more examples.

Supported Types
---------------
* Numbers
* Strings
* Array literals
* object literals
* function
* RegExp literals
* Dates
* true
* false
* undefined
* null
* NaN
* Infinity

Notes
-----
* Functions are serialized with `func.toString()`, no closure properties are serialized
* Multiple references to the same object become copies
* Circular references are encoded as `{$circularReference:1}`

License
-------
toSource is open source software under the [zlib license][2].

[1]: https://github.com/marcello3d/node-tosource/blob/master/test.js
[2]: https://github.com/marcello3d/node-tosource/blob/master/LICENSE
