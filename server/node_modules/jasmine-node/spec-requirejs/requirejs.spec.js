require(['requirejs.sut'], function(sut){
  describe('RequireJs basic tests', function(){
    beforeEach(function(){
        expect(true).toBeTruthy();
    });
    afterEach(function(){
        expect(true).toBeTruthy();
    });
    
    it('should load sut', function(){
      expect(sut.name).toBe('Subject To Test');
      expect(sut.method(2)).toBe(3);
    });

    it('should run setup', function(){
      expect(typeof setupHasRun).toBe('boolean');
    });
  });
});
