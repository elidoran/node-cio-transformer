# this uses the options provided (this) to create one or more Transform stream
# and pipe the socket into them and back to itself.
# accepts strings to require modules.
# accepts builder functions to create new transform instances
#
# when multiple sockets are created with the same options the module string
# will be reused and it'll just grab the cached require result.
#
# the builder functions will be called again to build new transform instances.
module.exports = (control) ->

  # get our option `transform`, which may be an array.
  transforms =
    if Array.isArray @transform then @transform
    else transforms = [ @transform ]

  # we want the socket. doesn't matter whether its for a client or server client
  socket = @client ? @connection

  # check each transform.
  #   1. require() string to get a builder function
  #   2. call a function to get a transform instance
  #   3. add error event forwarder from transform to socket
  for each,index in transforms

    if typeof each is 'string'

      try # expect require() to return a function
        each = require each
      catch error
        control.fail 'Unable to require transform from: ' + each, error
        return

    # call builder function and store result
    if typeof each is 'function' then each = transforms[index] = each()

    # forward errors to the socket  # TODO: necessary?
    unless each.__hasTransformerErroForwarder is true
      each.on 'error', (error...) -> socket.emit 'error', error...
      each.__hasTransformerErroForwarder = true

  # let's remember the last one
  last = transforms[transforms.length - 1]

  # # now pipe() them all

  # first, pipe the socket into the first transform
  socket.pipe transforms[0]

  # then, pipe each transform to the next one (except the last one)
  if transforms.length > 1
    for each,index in transforms when each isnt last
      each.pipe transforms[index + 1]

  # finally, pipe `last` back to the connection
  last.pipe socket

  # store the transform instances on the socket
  socket.transforms = transforms

  return
