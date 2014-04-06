require [ "cs!requirecs.sut" ], (sut) ->
  describe "RequireJs basic tests with spec and sut in CoffeeScript", ->
    it "should load coffeescript sut", ->
      expect(sut.name).toBe "CoffeeScript To Test"
      expect(sut.method(2)).toBe 4
