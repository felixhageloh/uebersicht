#=============================================================================
# Async spec, that will be time outed
#=============================================================================
describe 'async', ->
  it 'should be timed out', ->
    waitsFor (-> false), 'MIRACLE', 500

  doneFunc = (done) ->
    setTimeout(done, 10000)

  it "should timeout after 100 ms", doneFunc, 100
