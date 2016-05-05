# This is a simple example Widget, written in CoffeeScript, to get you started
# with Übersicht. For the full documentation please visit:
#
# https://github.com/felixhageloh/uebersicht
#
# You can modify this widget as you see fit, or simply delete this file to
# remove it.

# this is the shell command that gets executed every time this widget refreshes
command: "whoami"

# the refresh frequency in milliseconds
refreshFrequency: 1000000

# render gets called after the shell command has executed. The command's output
# is passed in as a string. Whatever it returns will get rendered as HTML.
render: (output) -> """
  <h1>Hi, #{output}</h1>
  <p>
    Thanks for trying out Übersicht!
    This is an example widget to get you started.
  </p>
  <p>
    To view this example widget, choose <em>'Open Widgets Folder'</em>
    from the status bar menu. Use it to create your own widget,
    or simply delete it.
  </p>
  <p>
    To download other widgets, choose <em>'Visit Widgets Gallery'</em>
    from the status bar menu.
  </p>
"""

# the CSS style for this widget, written using Stylus
# (http://learnboost.github.io/stylus/)
style: """
  background: rgba(#fff, 0.95) url('übersicht-logo.png') no-repeat 50% 20px
  background-size: 176px 84px
  -webkit-backdrop-filter: blur(20px)
  border-radius: 1px
  border: 2px solid #fff
  box-sizing: border-box
  color: #141f33
  font-family: Helvetica Neue
  font-weight: 300
  left: 50%
  line-height: 1.5
  margin-left: -170px
  padding: 120px 20px 20px
  top: 10%
  width: 340px
  text-align: justify

  h1
    font-size: 20px
    font-weight: 300
    margin: 16px 0 8px

  em
    font-weight: 400
    font-style: normal
"""
