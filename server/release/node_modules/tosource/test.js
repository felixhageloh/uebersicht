var toSource = require('./tosource')
var assert = require('assert')


// Various types
var date = new Date
var v = toSource(
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
        date,
        new Date("Wed, 09 Aug 1995 00:00:00 GMT")]
);

assert.equal(
    v,
    "[ 4,\n"+
    "  5,\n"+
    "  6,\n"+
    "  \"hello\",\n"+
    "  { \"1\":4,\n"+
    "    a:2,\n"+
    "    b:3,\n"+
    "    \"if\":5,\n"+
    "    yes:true,\n"+
    "    no:false,\n"+
    "    nan:NaN,\n"+
    "    infinity:Infinity,\n"+
    "    \"undefined\":undefined,\n"+
    "    \"null\":null,\n"+
    "    foo:function (bar) {\n"+
    "            console.log(\"woo! a is \"+a)\n"+
    "            console.log(\"and bar is \"+bar)\n"+
    "        } },\n"+
    "  /we$/gi,\n"+
    "  new Date("+date.getTime()+"),\n"+
    "  new Date(807926400000) ]"
)

// Filter parameter (applies to every object recursively before serializing)
assert.equal(
    toSource(
        [ 4, 5, 6, { bar:3 } ],
        function numbersToStrings(value) {
            return typeof value == 'number' ? '<'+value+'>' : value
        }
    ),
    "[ \"<4>\",\n"+
        "  \"<5>\",\n"+
        "  \"<6>\",\n"+
        "  { bar:\"<3>\" } ]"
)

// No indent
assert.equal(
    toSource([ 4, 5, 6, { bar:3 } ], null, false ),
    "[4,5,6,{bar:3}]"
)

// Circular reference
var object = {a:1, b:2}
object.c = object

assert.equal(
    toSource(object),
    "{ a:1,\n"+
    "  b:2,\n"+
    "  c:{$circularReference:1} }"
)

// Not a circular reference
foo = {}
object = {a:foo, b:foo}

assert.equal(
    toSource(object),
    "{ a:{},\n"+
    "  b:{} }"
)
