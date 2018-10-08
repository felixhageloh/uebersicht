# Übersicht
*Keep an eye on what's happening on your machine and in the world.*

For general info check out the [Übersicht website.](http://tracesof.net/uebersicht)

## Writing Widgets

In essence, widgets are plain JavaScript objects that define a few key properties and methods. They need to be defined in a single file with a `.js` or `.coffee` extension for Übersicht to pick them up. Übersicht will listen to file changes inside your widget directory, so you can edit widgets and see the result live.

You can also include node modules and split your widget into separate files using [NodeJS' module syntax](https://www.sitepoint.com/understanding-module-exports-exports-node-js/). Any file that is in a directory called `/node_modules`, `/lib` or `/src` will be treated as a module and will not show up as a separate widget.

Currently they are best written in [CoffeeScript](http://coffeescript.org). Plain JS widgets work as well, but it currently doesn't have CommonJS support. This documentation will use the CoffeScript syntax, but here is a small example widget [in pure JavaScript](https://gist.github.com/felixhageloh/34645a899a0f22f583bb). As an alternative, you could use CoffeScript's back-tick <tt>`</tt> operator to only write the relevant parts in JavaScript.

The following properties and methods are currently supported:


### command

A **string** containing the shell command to be executed, or
a **function(callback)** which eventually calls callback with some data.
For example:

```coffeescript
command: "echo Hello World"
```

Watch out for quotes inside commands. Often they need to properly escaped, like:

```coffeescript
command: "ps axo \"rss,pid,ucomm\" | sort -nr | head -n3"
```

Example using a command function:

```coffeescript
command: (callback) ->
  # example function that fetches data from a server
  fetchData 'some/url', (error, data) ->
    callback(error, data)
```

The first and only argument passed to a command function is a callback, which must be called to continue running the widget. It follows the standard NodeJS [error-first callback pattern](http://fredkschott.com/post/2014/03/understanding-error-first-callbacks-in-node-js/).


### refreshFrequency

An **integer** specifying how often the above command is executed. It defines the delay in milliseconds between consecutive commands executions. Example:

```coffeescript
refreshFrequency: 10000
```

You can also specify `refreshFrequency` as a string, like '2 days', '1d', '10h', '2.5 hrs', '2h', '1m', or '5s'.

```coffeescript
refreshFrequency: '10s'  # equates to 10000
```

The default is 1000 (1s). If set to `false` the widget won't refresh automatically.

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

For convenience, the [nib library](https://tj.github.io/nib/) for Stylus is included, so mixins for CSS3 are available.

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

## Widget Internals

For writing more advanced widgets you might not want to rely on the standard 'run command, then redraw' cycle and instead manage some of the widget internals yourself. There are a few methods you can use from within `render`, `afterRender` and `update`

### @stop()

Stop the widget from updating if a `refreshFrequency` is set. The widget won't update until `@start` is called.

### @start()

Start updating a previously stopped widget again. Does nothing if `refreshFrequency` is set to `false`.

### @refresh()

Runs the command and redraws the widget as it normally would as part of a refresh cycle. If no command is set, the widget will only redraw.

### @run(command, callback)

Runs a shell command and calls callback with the result. Command is a string containing the shell command, just like the `command` property of a widget. Callback is called with err (if any) and stdout, in standard node fashion.

## Geolocation API

While the WebView used by Übersicht seems to provide the standard HTML5 geolocation API, it is not functional and there seems to be no way to enable it. Übersicht now provides a custom implementation, which tries to follow the standard implementation as closely as possible. However, so far it provides only the basics and might still be somewehat unstable. The api can be found under `window.geolocation` (instead of `window.navigator.geolocation`). And supports the following methods

```coffeescript
geolocation.getCurrentPosition(callback)
```

```coffeescript
geolocation.watchPosition(callback)
```

```coffeescript
geolocation.clearWatch(watchId)
```

Check the [documentation](https://developer.mozilla.org/en-US/docs/Web/API/Geolocation) for details on how to use these methods. The main difference to the standard API is that none of them accept options (the accuracy for position data is always set to the highest) and error reporting has not be implemented yet.

However, in a adition to the standard `Position` object provided by the standard API, Übersicht provides an extra `address` property with the following fields:

  - Street
  - City
  - ZIP
  - Country
  - State
  - CountryCode


## Hosted Functionality

A global object called `uebersicht` exists which exposes extra functionality that is typically not available in a browser. At the moment it is very limited:


### uebersicht.makeBgSlice(canvas)

Has been deprecated as of version 0.8 in favor of -webkit-backdrop-filter. It should be available on all systems that have Safari 9+ installed. https://developer.mozilla.org/en-US/docs/Web/CSS/backdrop-filter

## Built In Proxy Server

If you like you make Ajax requests to an external site without using a command, you can make use of the built in proxy server. It is running on `http://127.0.0.1:41417` and can be used as follows:

    command: (callback) ->
      proxy = "http://127.0.0.1:41417/"
      server = "http://example.com:8080"
      path = "/getsomejson"
      $.get proxy + server + path, (json) ->
        callback null, json

## Scripting Support

Übersicht has AppleScript support since version 1.1.45. To get detailed information on what you can script, open the Script Editor and add Übersicht to the Library (use Window -> Library to show). Here are a few examples of what you can do with AppleScript:

    tell application "Übersicht" to refresh

refreshes all widgets.

    tell application "Übersicht" to refresh widget id "my-widget"

refreshes widget with id "my-widget".

    tell application "Übersicht" to every widget

lists all widgets.

    tell application "Übersicht" to set hidden of widget id "top-cpu-coffee" to false

hides the widget with ID "top-cpu-coffee"

### Typing the umlaut 'Ü'

Unfortunately OS X seems to use a different UTF-8 code point for the Ü in its file system than you get by typing it normally (or by copy pasting it from here). There are three ways you can get the correct character:

- use the Script Editor of OS X and add Übersicht to its library. Once you initiate a new script via the Editor it will contain the correct name of the app.
- while Übersicht is running, list the process using `ps ax | grep sicht` and copy paste the name from there
- rename the app to whatever you like ('Uebersicht' would be the correct spelling without using the umlaut)

## Building Übersicht

To build Übersicht you will need to have NodeJS and a few dependencies installed:

### setup

Install node and npm using homebrew

    brew install node

then run

    npm install

### git and unicode characters

Git might not like the umlaut (ü) in some of the path names and will constantly show them as untracked files. To get rid of this issue, I had to use

    git config core.precomposeunicode false

However, the common advice is to set this to `true`. It might depend on the OS and git version which one to use.

### building

The code base consists of two parts, a cocoa app and a NodeJS app inside `server/`. To build the node app seperately, use `npm run release`. This happens automatically every time you build using XCode.

The node app can be run standalone using

```coffeescript
coffee server/server.coffee -d <path/to/widget/dir> -p <port>
```

# Building in Xcode

The first time opening the project in Xcode you might see this message when trying to build: "The run destination My Mac is not valid for Running the scheme 'Übersicht'."

Click on `Uebersicht` in the project navigator and then select the menu `Editor > Validate Settings...` and click `Perform Changes`.

You can then attempt to build, you may then be presented with code sign issues, click `Fix Issue` to continue.

Now you need to remove the code signing shell script, select the `Übersicht` target and under `Build Phases` remove the code in the `Code Sign Frameworks` section.

You should now be able to build successfully.

There is one last step on the Node.js side to complete. For the sake of brevity, this link will solve your problem:

http://stackoverflow.com/questions/31254725/transport-security-has-blocked-a-cleartext-http

# Legal

The source for Übersicht is released under the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

© 2016 Felix Hageloh
