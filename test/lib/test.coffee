assert = require 'assert'
buildCio = require 'cio'
buildListener = require '../../lib'

transforming = require('transforming')()

# no builder options yet...
cio = buildCio()


# 1. a transform instance
instance = transforming.string().toString (string) -> string + ' (intance) '
instance.id = 'instance'

# 2. a builder function
builder = (options) ->
  t = transforming.string().toString (string) -> string + ' (builder) '
  t.id = 'builder'
  return t

# 3. a require'able (requires messing with require())
requirable = fakePath = require('path').resolve('./fake.js')
Module = require('module')
realResolve = Module._resolveFilename
Module._resolveFilename = (request, parent) ->
  if request is fakePath then fakePath else realResolve request, parent

requiredTransform = null

require.cache[fakePath] =
  id: fakePath
  filename: fakePath
  loaded: true
  exports: (options) ->
    requiredTransform = transforming.string().toString (string) -> string + ' (requirable) '
    requiredTransform.id = 'requirable'
    return requiredTransform


# now the testing

describe 'test transformer', ->

  describe 'with socket and array of transforms', ->

    builderOptions =
      transform: [
        instance
        builder
        requirable
      ]

    # build the listener
    listener = buildListener builderOptions

    # pass a fake socket to the listener
    fakeSocket =
      onEvents: {}
      onceEvents: {}
      emits: {}
      pipe: (stream) ->
        stream.pipedFrom = this
        return stream
      on: (event, listener) ->
        if @onEvents[event]?
          @onEvents[event] = [@onEvents[event], listener]
        else
          @onEvents[event] = listener
      once: (event, listener) ->
        @onceEvents[event] = listener
      emit: (event, args...) ->
        @emits[event] = args

    # call the listener as if a new socket connection has been made
    listener fakeSocket

    it 'should return a listener function', ->
      assert.equal (typeof listener), 'function'

    it 'should call listener to create the transforms array', ->
      assert.equal fakeSocket.transforms.length, 3, 'should have 3 transforms'

    it 'should add an error listener', -> assert fakeSocket.onEvents.error

    it 'should pipe to the first tranfsorm', ->
      assert.equal instance.pipedFrom, fakeSocket

    it 'should pipe last to socket', ->
      assert.equal fakeSocket.emits.pipe[0], requiredTransform


    # TODO: test emitting something and ensure it goes out thru fakeSocket?
