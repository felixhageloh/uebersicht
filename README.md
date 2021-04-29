# Übersicht
*Keep an eye on what's happening on your machine and in the world.*

For general info check out the [Übersicht website.](http://tracesof.net/uebersicht)

## Writing Widgets

In essence, widgets are JavaScript modules that expose a few key properties and methods. They need to be defined in a single file with a `.jsx` extension for Übersicht to pick them up. Previously, widgets could be written in CoffeeScript and are still supported. Check [the old documentation](ClassicWidgets.md) for details. Übersicht will listen to file changes inside your widget directory, so you can edit widgets and see the result live.

Widget rendering is done using [React](https://reactjs.org) and its [JSX](https://reactjs.org/docs/introducing-jsx.html) syntax. Simple widget state is managed for you by Übersicht, but for more advanced widgets you can manage state using a Redux-like pattern. You `dispatch` events, which get processed by a single `updateState` function which returns the new state, which is passed to the render function of your widget.

State is kept when you modify your widget, which allows for live coding. Any changes to the UI of your widget will be immediately visible.  One drawback (at least with the current implementation) is that if you change the shape of your state you might have to 'Refresh all Widgets' from the app menu for your widget to work.

You can also include node modules and split your widget into separate files using [ESM syntax](http://2ality.com/2014/09/es6-modules-final.html). Any file that is in a directory called `/node_modules`, `/lib` or `/src` will be treated as a module and will not show up as a separate widget.

The following properties and methods are supported:

### command

A **string** containing the shell command to be executed, or<br>
a **function(dispatch : function)** which eventually dispatches an event,
or **undefined** meaning that no command will be executed for this widget.

For example:

```jsx
export const command = "echo Hello World";
```

Watch out for quotes inside commands. Often they need to properly escaped, like:

```jsx
export const command = "ps axo \"rss,pid,ucomm\" | sort -nr | head -n3";
```

Example using a command function:

```jsx
export const command = (dispatch) =>
  fetch('some/url.json)')
    .then((response) => {
      dispatch({ type: 'FETCH_SUCCEDED', data: response.json() });
    })
    .catch((error) => {
      dispatch({ type: 'FETCH_FAILED', error: error });
    });
```

The first and only argument passed to a command function is a `dispatch` function, which you can use to dispatch plain JasvaScript objects, called events, to be picked up by your `updateState` function.


### refreshFrequency

An **number** specifying how often the above command is executed.

It defines the delay in milliseconds between consecutive commands executions. Example:

```coffeescript
export const refreshFrequency = 1000; // widget will run command once a second
```

The default is 1000 (1s). If set to `false` the widget won't refresh automatically.

### className

An **object** or **string** defining the CSS rules to applied to the root of your widget.

It is most commonly used control the position of your widget. It is converted to a CSS class name using the [Emotion CSS-in-JS library](https://emotion.sh/docs/css). Read more about [styling your widgets here](#styling-widgets).

```jsx
export const className = {
  top: 0,
  left: 0,
  color: '#fff'
}
```

or

```jsx
export const className = `
  top: 0;
  left: 0;
  color: #fff;
`
```

Note that widgets are positioned absolute in relation to the screen (minus the menu bar), so a widget with `top: 0` and `left: 0` will be positioned in the top left corner of the screen, just below the menu bar.

### render : props

A **function(props : object)** to render your widget.

If you know [React functional components](https://reactjs.org/docs/components-and-props.html) you know how render works. The `props` passed to this function is whatever state your `updateState` function returns. If you don't provide your own `updateState` function, the default props that are passed are `output` and `error`, containing the output your command produced and any error that might have occurred.

```jsx
export const render = ({output, error}) => {
  return error ? (
    <div>Something went wrong: <strong>{String(error)}</strong></div>
  ) : (
    <div>
      <h1>We got some output!</h1>
      <p>{output}</p>
    </div>
  );
}
```

The default implementation of render just returns `output`.

### updateState : event, previousState

A **function(event : object, previousState : object)** implementing the state update behavior of this widget.

When provided, this function must return the next state, which will be passed as `props` to your render function. The default function will return `output` and `error` from the event object.

```jsx
export const updateState = (event, previousState) => {
  if (event.error) {
    return { ...previousState, warning: `We got an error: ${event.error}` };
  }
  const [cpuPct, processName] = event.output.split(',');
  return {
    cpuPct: parseFloat(cpuPct),
    processName
  };
}
```
This will pass a props object containing `cpuPct` and `processName` to the render function. If an error occurred, it will pass the previous state plus a warning message.

If your widget has more complex state logic, for example because it is fetching data from several different sources, it is a good idea to add a `type` property to your events. You can use this type to decide how to update your state. For example:

```jsx
export const updateState = (event, previousState) => {
  switch(event.type) {
    case 'CO2_FETCHED': return updateCo2(event.output, previousState);
    case 'TEMPERATURE_FETCHED': return updateTemp(event.output, previousState);
    default: {
      return previousState;
    }
  }
}
```

This example also shows that you can make use of functions to further break down your state update logic.

### initialState

An **object** with the initial state of your widget.

If you provide a custom `updateState` function you might need to define the initial state that gets passed on initial render of the widget. before any command has been run.

```jsx
export const initialState = { output: 'fetching data...' };
```

The default initial state is `{ output: '' }`.

### init : dispatch

A **function(dispatch : function)** that is called the first time your widget loads. Many widgets won't need this, but you can use this function to perform any initial setup for more advanced use cases. For example, instead of relying on periodic shell commands, you might want to open and listen to WebSocket events to update your widget.

```jsx
export const init = (dispatch) => {
  const socket = new WebSocket('ws://localhost:8080');

  socket.addEventListener('message',  (event) => {
    dispatch({type: 'MESSAGE_RECEIVED', data: event.data});
  });
}
```

## Styling Widgets

Uebersicht comes bundled with [Emotion ](https://emotion.sh) (version 9). It exposes it's `css` and `styled` functions via the `uebersicht` module.

As described above, you can use `className` to style and position the root node of your widget. For further styling you can do something like this:

```jsx
import { css } from "uebersicht"

const header = css`
  font-family: Ubuntu;
  font-size: 20px;
  text-align: center;
  color: white;
`

const boxes = css`
  display: flex;
  justify-content: center;
`

const box = css({
  height: "40px",
  width: "40px",
  "& + &": {
    marginLeft: "5px"
  }
})

export const className = `
  left: 20px;
  top: 20px;
  width: 200px;
`

export const initialState = { colors: ["DeepPink", "DeepSkyBlue", "Coral"] }

export const render = ({ colors }) => {
  return (
    <div>
      <h1 className={header}>Some colored boxes</h1>
      <div className={boxes}>
        {colors.map((color, idx) => (
          <div className={`${box} ${css({ background: color })}`} key={idx} />
        ))}
      </div>
    </div>
  )
}
```

Alternatively, you can also make use of Emotion's styles components:

```jsx
import { styled } from "uebersicht"

const Header = styled("h1")`
  font-family: Ubuntu;
  font-size: 20px;
  text-align: center;
  color: white;
`

const Boxes = styled("div")`
  display: flex;
  justify-content: center;
`

const Box = styled("div")(props => ({
  height: "40px",
  width: "40px",
  background: props.color,
  marginRight: "5px"
}))

export const className = `
  left: 20px;
  top: 20px;
  width: 200px;
`

export const initialState = { colors: ["DeepPink", "DeepSkyBlue", "Coral"] }

export const render = ({ colors }) => {
  return (
    <div>
      <Header>Some colored boxes</Header>
      <Boxes>
        {colors.map((color, idx) => (
          <Box color={color} key={idx} />
        ))}
      </Boxes>
    </div>
  )
}
```

Finally, since you can also install and import any module you like, you can use your favorite styling library instead.

## Running Shell Commands

If need to run extra shell commands without using the [command](#command) property, you can import the `run` function from the `uebersicht` module.

It returns a Promise, which will resolve to the output of the command (stdout) or reject if any error occurred.

```jsx
import { run } from 'uebersicht'

export const render => (props, dispatch) {
  return (
    <button
      onClick={() => {
        run('echo "new output"')
          .then((output) => dispatch({type: 'OUTPUT_UPDATED', output}))
      }}
    >
      Update
    </button>
  );
}
```
> Note that in order to receive click events you need to configure an interaction shortcut and give Übersicht accessibility access.

## Geolocation API

While the WebView used by Übersicht seems to provide the standard HTML5 geolocation API, it is not functional and there seems to be no way to enable it. Übersicht now provides a custom implementation, which tries to follow the standard implementation as closely as possible. However, so far it provides only the basics and might still be somewhat unstable. The api can be found under `window.geolocation` (instead of `window.navigator.geolocation`). And supports the following methods

```js
geolocation.getCurrentPosition(callback)
```

```js
geolocation.watchPosition(callback)
```

```js
geolocation.clearWatch(watchId)
```

Check the [documentation](https://developer.mozilla.org/en-US/docs/Web/API/Geolocation) for details on how to use these methods. The main difference to the standard API is that none of them accept options (the accuracy for position data is always set to the highest) and error reporting has not be implemented yet.

However, in a addition to the standard `Position` object provided by the standard API, Übersicht provides an extra `address` property with the following fields:

  - Street
  - City
  - ZIP
  - Country
  - State
  - CountryCode


## Built In Proxy Server

If you like you make Ajax requests to an external site without using a command, you can make use of the built in proxy server. It is running on `http://127.0.0.1:41417` and can be used as follows:

    command: (callback) ->
      proxy = "http://127.0.0.1:41417/"
      server = "http://example.com:8080"
      path = "/getsomejson"
      $.get proxy + server + path, (json) ->
        callback null, json

## Scripting Support

Übersicht has AppleScript support since version 1.1.45. To get detailed information on what you can script, open the Script Editor and add Übersicht to the Library (use Window -> Library to show). Here are a few examples of what you can do with AppleScript. (Note that the examples all use the application id instead of the app name. This is because typing the umlaut Ü can be tricky):

    tell application id "tracesOf.Uebersicht" to refresh

refreshes all widgets.

    tell application id "tracesOf.Uebersicht" to refresh widget id "my-widget"

refreshes widget with id "my-widget".

    tell application id "tracesOf.Uebersicht" to every widget

lists all widgets.

    tell application id "tracesOf.Uebersicht" to set hidden of widget id "top-cpu-coffee" to false

hides the widget with ID "top-cpu-coffee"


## Building Übersicht

To build Übersicht you will need to have NodeJS and a few dependencies installed:

### setup

Currently, the project supports node 8.

If you already have node, you'll have to
```
brew unlink node
```
Now, install node 8 using homebrew
```
brew install node@8 && brew link --force node@6
```
then run
```
npm install
```
### git and unicode characters

Git might not like the umlaut (ü) in some of the path names and will constantly show them as untracked files. To get rid of this issue, I had to use

    git config core.precomposeunicode false

However, the common advice is to set this to `true`. It might depend on the OS and git version which one to use.

### building

The code base consists of two parts, a cocoa app and a NodeJS app inside `server/`. To build the node app separately, use `npm run release`. This happens automatically every time you build using XCode.

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

© 2019 Felix Hageloh
