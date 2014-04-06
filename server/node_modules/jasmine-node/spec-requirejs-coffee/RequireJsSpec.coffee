require [ "requirecs.sut" ], (sut) ->
  describe "RequireJs basic tests with spec in CoffeeScript", ->
    it "should load javascript sut", ->
      expect(sut.name).toBe "CoffeeScript To Test"
      expect(sut.method(2)).toBe 4
