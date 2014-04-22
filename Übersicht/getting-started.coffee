command: "whoami"

refreshFrequency: 1000000

render: (output) -> """
  <h1>Hi, #{output}</h1>
  <p>
    Thanks for trying out Übersicht! You can download new widgets from:
    <strong>http://tracesof.net/uebersicht-widgets/</strong>
    To view this example widget, choose 'Open Widgets Folder' from the status bar menu.
  </p>
"""

style: """
  background: rgba(#fff, 0.95) url('übersicht-logo.png') no-repeat 50% 20px
  background-size: 176px 84px
  border-radius: 1px
  border: 2px solid #fff
  box-sizing: border-box
  color: #141f33
  font-family: Helvetica Neue
  font-weight: 300
  left: 50%
  line-height: 1.5
  margin-left: -160px
  padding: 120px 20px 20px
  top: 10%
  width: 320px
  text-align: justify

  h1
    font-size: 20px
    font-weight: 300
    margin: 16px 0 8px

  strong
    background: #ad7a7c
    color: #fff
    display: block
    font-size: 16px
    font-style: italic
    font-weight: 200
    margin: 12px -20px
    padding: 8px 20px
"""
