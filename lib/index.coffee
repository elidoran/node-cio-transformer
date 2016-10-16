
# this is the builder function to make the listener function
module.exports = (builderOptions) ->

  # alias for now:
  opts = builderOptions

  # return error if a transform isn't provided
  unless opts?.transform?
    return error:'Must specify at least one transform'

  # if there are strings then try require'ing them now to ensure they're available

  # do we have one transform or an array of transforms?
  if Array.isArray opts?.transform then transforms = opts.transform
  else transforms = [opts.transform]

  # check if transforms must be require()'d
  for each,index in transforms
    if typeof each is 'string' # then require it
      try # store the required result back into the transforms array
        transforms[index] = require each
      catch error # return an object with an error message and the Error
        return error:'Unable to require transform from:'+each, Error:error

  # return the listener function
  return listener = (socket) ->

    # let's hold our created transform instances in this array
    array = []

    # check if transforms must be built.
    for each,index in transforms
      if typeof each is 'function' then each = each builderOptions
      array.push each
      # also, take this opportunity to forward errors to the connection
      each.on 'error', (error...) -> socket.emit 'error', error...

    # let's remember the last one
    last = array[array.length - 1]

    # # now pipe() them all

    # first, pipe the connection into the first transform
    socket.pipe array[0]

    # then, pipe each transform to the next one (except the last one)
    if array.length > 1
      for each,index in array when each isnt last
        each.pipe array[index + 1]

    # finally, pipe `last` back to the connection
    last.pipe socket

    # store the transform instances on the socket
    socket.transforms = array

    # handle common error response
    socket.on 'error', (error) ->
      console.error 'Connection error:',error.message
