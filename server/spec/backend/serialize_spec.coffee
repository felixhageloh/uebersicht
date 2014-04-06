describe 'serialize', ->
  serialize = require '../../src/serialize.coffee'

  describe 'given some widgets', ->
    lastId = 0
    makeWidget = (attrs) ->
      attrs.id = lastId++
      id: attrs.id,
      serialize: -> JSON.stringify(attrs)

    it 'should return a jsonified object of the form id: <serialized widget>', ->
      widget     = makeWidget(foo: 'bar')
      serialized = serialize([widget])

      expect(serialized).toEqual "({'#{widget.id}': #{widget.serialize()}})"
      expect(serialized.indexOf('foo')).not.toBe -1
      expect(serialized.indexOf('bar')).not.toBe -1

    it 'should serialize all widgets', ->
      widgets    = [makeWidget(foo: 'bar'), makeWidget(bar: 'baz')]
      serialized = serialize widgets

      expect(serialized.indexOf(widgets[0].id)).not.toBe -1
      expect(serialized.indexOf(widgets[1].id)).not.toBe -1
      expect(serialized.indexOf(widgets[0].serialize())).not.toBe -1
      expect(serialized.indexOf(widgets[1].serialize())).not.toBe -1


  describe 'given no widgets', ->
    it 'should return a serialize empty opject', ->
      expect(serialize []).toEqual '({})'
      expect(serialize null).toEqual '({})'
