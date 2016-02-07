# Widget  = require '../../src/widget.coffee'
# path    = require 'path'

# describe 'widget', ->
#   describe 'given a valid config', ->
#     describe 'with minimal attributes', ->
#       widget = Widget command: 'bar'

#       it 'should create a widget', ->
#         expect(widget).not.toBe null

#       it 'should set a default refreshFrequency', ->
#         expect(widget.refreshFrequency).toBe 1000

#       it 'provide a serialize method', ->
#         expect(widget.serialize()).toContain 'command:"bar"'

#       it 'provide a default style', ->
#         css = eval( '(' + widget.serialize() + ')').css
#         expect(css).toEqual "#widget {\n  top: 30px;\n  left: 10px;\n}\n"

#     describe 'with other attributes', ->

#       it 'should use the provided refreshFrequency', ->
#         widget = Widget command: 'bar', refreshFrequency: 666
#         expect(widget.refreshFrequency).toBe 666

#       it 'parse and scope the provided style', ->
#         widget = Widget command: 'bar', style: "left: 100px"
#         css = eval( '(' + widget.serialize() + ')').css
#         expect(css).toEqual "#widget {\n  left: 100px;\n}\n"

#       it 'parse more complex styles', ->
#         expect(->
#           Widget command: 'bar', style: "left: 100px\ntop: 44px"
#         ).not.toThrow()

#   describe 'given an invalid valid config', ->
#     it 'should raise the appropriate error', ->
#       expect( -> Widget() ).toThrow new Error("empty implementation")
#       expect( -> Widget({}) ).toThrow new Error("no command given")
#       expect( -> Widget({foo: 'bar'}) ).toThrow new Error("no command given")
#       expect( -> Widget("garbage") ).toThrow new Error("no command given")

