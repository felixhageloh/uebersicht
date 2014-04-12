# Übersicht

*Keep an eye on what's happening on your machine and in thew world*


## Writing Widgets

In essence, widgets are plain JavaScript objects that define a few key properties and methods. They need to be defined in a single file with a `.js` or `.coffee` extension for Übersicht to pick them up. Übersicht will listen to file changes inside your widget directory, so you can edit widgets and see the result live.

They can also be written in CoffeeScript which has a cleaner multi-line string syntax that comes in handy in several places. This documentation will use the CoffeScript syntax. The following properties and methods are currently supported:


### command `required`


A **string** containing the shell command to be executed, for example:

    command: "echo Hello World"

Note, that in some cases they need to properly escaped, like:

    command: "ps axo \"rss,pid,ucomm\" | sort -nr | head -n3"


### refreshFrequency

An **integer** specifying how often the above command is executed. It defines the delay in milliseconds between consecutive commands executions. Example:

    refreshFrequency: 10000

the default is 1000 (1s).

### style

A **string** defining the css style of this widget, which is also used to control the position. In order to allow for easy scoping of CSS rules, styles are written using the [Stylus](http://learnboost.github.io/stylus/) preprocessor. Example:

    style: """
      top:  0
      left: 0
      color: #fff

      .some-class
        box-shadow: 0 0 2px rgba(#000, 0.1)
    """

For convenience, the [nib library](http://visionmedia.github.io/nib/) for Stylus is included, so mixins for CSS3 are available.

Note that widgets are positioned absolute in relation to the screen (minus the menu bar), so a widget with `top: 0` and `left: 0` will be positioned in the top left corner of the screen, just below the menu bar.


### render (output)

A **function** returning a HTML string to render this widget. It gets the output of `command` passed in as a string. For example, a widget with:

    command: "echo Hello World!"

    render: (output) -> """
      <h1>#{output}</h1>
    """

would render as **Hello World!**. Usually, your `output` will be something more complicated, for example a JSON string, so you will have to parse it first.

The default implementation of render just returns `output`


### update (output, domEl)

A **function** implementing update behavior of this widget. If specified, `render` will be called once when the widget is first initialized. Afterwards, update will be called for every refresh cycle. If no update method is provided, `render` will be called instead.

Since, `render` will simply replace the inner HTML of a widget every time, you can use render to do a partial update of your widgets, kick off animations etc. For example, if the output of your command returns a percentage, you could do something like:

    # we don't care about output here
    render: (_) -> """
      <div class='bar'></div>
    """

    update: (output, domEl) ->
      $(domEl).find('.bar').css height: output+'%'

This will set the height of .bar every time this widget refreshes. As you can see, jQuery is available.


## Building Übersicht

The code base consists of two parts, a cocoa app and a NodeJS app inside `server/`. To build the node app, use `grunt release`, then build the cocoa app using Xcode. Unfortunately you have to clean your build (⇧⌘K) every time you build the node app.

The node app can be run standalone using

    coffee server/server.coffee -d <path/to/widget/dir> -p <port>

Then point your browser to `localhost:<port>`. Naturally, you will need to have NodeJS and the following dependcies installed:

    npm install -g coffee-script
    npm install -g grunt-cli

While developing you can use

    cd server
    grunt

To continuously watch, compile and run specs.

