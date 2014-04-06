command: "whoami"

refreshFrequency: 1000000

render: (output) -> """
  <h1>Hi, #{output}</h1>
  <p>
    Thanks for trying out Übersicht! Your widgets can be found in:
    <code>~/Library/Application Support/Übersicht/widgets</code>
  </p>
"""

style: """
  left: 50%
  top: 10%
  width: 600px
  margin-left: -320px
  padding: 120px 20px 20px
  color: #141f33
  font-family: Helvetica Neue
  background: rgba(#fff, 0.8) url('übersicht-logo.png') no-repeat 50% 20px
  background-size: 176px 84px
  border-radius: 2px

  h1
    font-size: 20px

  code
    display: block
    background: #2d2d2d
    margin: 20px 0
    padding: 4px
    border-radius: 2px
    font-size: 20px
    color: #ddd
"""
