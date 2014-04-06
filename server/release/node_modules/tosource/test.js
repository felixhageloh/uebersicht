var toSource = require('./tosource')


// Various types
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
    new Date,
    new Date("Wed, 09 Aug 1995 00:00:00 GMT")]
))

// Filter parameter (applies to every object recursively before serializing)
console.log(
    toSource(
        [ 4, 5, 6, { bar:3 } ],
        function numbersToStrings(value) {
            return typeof value == 'number' ? '<'+value+'>' : value
        }
    )
)

// No indent
console.log(
    toSource([ 4, 5, 6, { bar:3 } ], null, false )
)

// Circular reference
var object = {a:1, b:2}
object.c = object

console.log(toSource(object))
