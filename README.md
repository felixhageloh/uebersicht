# Übersicht
*Keep an eye on what's happening on your machine and in the world.*

For general info check out the [Übersicht website.](http://tracesof.net/uebersicht)

## Writing Widgets

In essence, widgets are plain JavaScript objects that define a few key properties and methods. They need to be defined in a single file with a `.js` or `.coffee` extension for Übersicht to pick them up. Übersicht will listen to file changes inside your widget directory, so you can edit widgets and see the result live.

They can also be written in [CoffeeScript](http://coffeescript.org) which has a cleaner multi-line string syntax that comes in handy in several places. This documentation will use the CoffeScript syntax, but here is a small example widget [in pure JavaScript](https://gist.github.com/felixhageloh/34645a899a0f22f583bb). As an alternative, you could use CoffeScript's back-tick <tt>`</tt> operator to only write the relevant parts in JavaScript.

The following properties and methods are currently supported:


### command
> _required_


A **string** containing the shell command to be executed, for example:

```coffeescript
command: "echo Hello World"
```


Note, that in some cases they need to properly escaped, like:

```coffeescript
command: "ps axo \"rss,pid,ucomm\" | sort -nr | head -n3"
```

### refreshFrequency

An **integer** specifying how often the above command is executed. It defines the delay in milliseconds between consecutive commands executions. Example:

```coffeescript
refreshFrequency: 10000
```

the default is 1000 (1s).

### style

A **string** defining the css style of this widget, which is also used to control the position. In order to allow for easy scoping of CSS rules, styles are written using the [Stylus](http://learnboost.github.io/stylus/) preprocessor. Example:

```coffeescript
style: """
  top:  0
  left: 0
  color: #fff

  .some-class
    box-shadow: 0 0 2px rgba(#000, 0.1)
"""
```

For convenience, the [nib library](http://visionmedia.github.io/nib/) for Stylus is included, so mixins for CSS3 are available.

Note that widgets are positioned absolute in relation to the screen (minus the menu bar), so a widget with `top: 0` and `left: 0` will be positioned in the top left corner of the screen, just below the menu bar.


### render : output

A **function** returning a HTML string to render this widget. It gets the output of `command` passed in as a string. For example, a widget with:

```coffeescript
command: "echo Hello World!"

render: (output) -> """
  <h1>#{output}</h1>
"""
```

would render as **Hello World!**. Usually, your `output` will be something more complicated, for example a JSON string, so you will have to parse it first.

The default implementation of render just returns `output`.

### afterRender : domEl

A **function** that gets called, as the name suggests, after `render` with a reference to our newly rendered DOM element. It can be used to do one time setups that you wouldn't want to do on every update.


### update : output, domEl

A **function** implementing update behavior of this widget. If specified, `render` will be called once when the widget is first initialized. Afterwards, update will be called for every refresh cycle. If no update method is provided, `render` will be called instead.

Since `render` will simply replace the inner HTML of a widget every time, you can use render to do a partial update of your widgets, kick off animations etc. For example, if the output of your command returns a percentage, you could do something like:

```coffeescript
# we don't care about output here
render: (_) -> """
  <div class='bar'></div>
"""

update: (output, domEl) ->
  $(domEl).find('.bar').css height: output+'%'
```

This will set the height of .bar every time this widget refreshes. As you can see, jQuery is available.

## Hosted Functionality

A global object called `uebersicht` exists which exposes extra functionality that is typically not available in a browser. At the moment it is very limited:


### uebersicht.makeBgSlice(canvas)

Can be called with a canvas element to render a slice of the desktop wallpaper. This can be used to create filter effects, like blur, with the background. The dimensions of the slice are determined by the size and position of the canvas element. They are chosen so that they match exactly what would be directly underneath the canvas element. This means, it is important that the canvas element is correctly positioned before this method is called.
Calling `makeBgSlice` is like registering an event handler. The background slice will get re-rendered every time the wallpaper changes, so there is no need to call this method repeatedly. In fact, just like an event handler, you should not call this method repeatedly on the same DOM element. For this reason `afterReander` is usually the best place to call this method from.


## Building Übersicht

To build Übersicht you will need to have NodeJS and a few dependencies installed:

### setup

Install node and npm using homebrew

    brew install node

then run

    npm install -g coffee-script
    npm install -g grunt-cli

finally, inside the project dir run

    npm install

### git and unicode characters

Git might not like the umlaut (ü) in some of the path names and will constantly show them as untracked files. To get rid of this issue, I had to use

    git config core.precomposeunicode false

However, the common advice is to set this to `true`. It might depend on the OS and git version which one to use.s

### building

The code base consists of two parts, a cocoa app and a NodeJS app inside `server/`. To build the node app seperately, use `grunt release`. This happens automatically every time you build using XCode.

The node app can be run standalone using

```coffeescript
coffee server/server.coffee -d <path/to/widget/dir> -p <port>
```

Then point your browser to `localhost:<port>`. While developing you can use

    cd server
    grunt

to continuously watch, compile and run specs.

# Legal

The source for Übersicht is released under the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

© 2014 Felix Hageloh
