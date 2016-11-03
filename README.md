# @cio/transformer
[![Build Status](https://travis-ci.org/elidoran/node-cio-transformer.svg?branch=master)](https://travis-ci.org/elidoran/node-cio-transformer)
[![Dependency Status](https://gemnasium.com/elidoran/node-cio-transformer.png)](https://gemnasium.com/elidoran/node-cio-transformer)
[![npm version](https://badge.fury.io/js/%40cio%2Ftransformer.svg)](http://badge.fury.io/js/%40cio%2Ftransformer)

Easily use a Transform pipeline to handle communication.

## Install

```sh
npm install @cio/transformer --save
```

## Usage

Uses specified transforms in a pipeline from socket input back to socket output.

Accepts a single transform or an array of transforms.

Accepts the actual transform instance, a function to build the transform, or a string it can provide to `require()` to get a builder function.

Note: A server should (very likely) use builder functions to make a new transform for each connection.

```javascript
// get the `cio` module's builder function and build one
var buildCio = require('cio')
  , cio = buildCio();

// provide the module name to load it for the specific type of socket
cio.onClient('@cio/transformer');
cio.onServerClient('@cio/transformer');

// OR: provide the function
var fn = require('@cio/transformer');
cio.onClient(fn);
cio.onServerClient(fn);


// shows 3 different ways to provide a transform to use.
// shows specifying a single transform and an array of them
var transformModule = 'some-module'
  , buildTransform = require(transformModule)
  , someTransform = buildTransform()
  , optionsAsInstance = { transform: someTransform }
  , optionsAsBuilder = { transform: buildTransform }
  , optionsAsString = { transform: transformModule }
  , optionsWithMultiple = {
      // can mix any of the types
      transform: [
        someTransform    // uses instance (not good for server)
        buildTransform,  // calls buildTransform()
        transformModule, // does a require(), then calls function
      ]
  };

// then create a client. these all produce the same thing:
var client = cio.client(optionsAsInstance)
  , client = cio.client(optionsAsBuilder)
  , client = cio.client(optionsAsString);
// does:
//   client.pipe(someTransform).pipe(client)

// the string and function type will be used to get a new transform
// and then all three are piped in sequence.
var client = cio.client(optionsWithMultiple);
// final result is:
//   client.pipe(someTransform).pipe(someTransform2).pipe(someTransform3).pipe(client)
```


## Build Transform

There are multiple ways to build a Transform.

1. Use the standard methods described in Node's `stream` [documentation](https://nodejs.org/docs/latest/api/stream.html#stream_api_for_stream_implementers) (Note, this link is for the latest Node, be sure to check for the version you're using).
2. Use a helper module such as [through](https://www.npmjs.com/package/through) or [through2](https://www.npmjs.com/package/through2)
3. Use a builder module [transforming](https://www.npmjs.com/package/transforming) (Note, I made this module...)

```javascript
// standard Node way (newer versions):
// Note: this way requires splitting incoming string on newlines via another
//       transform piped to this one, or, done manually in your function.
var Transform = require('stream').Transform;
function builder1(options) {
  return new Transform({
    transform: function (data, encoding, next) {
      var string = data.toString('utf8')
        , object = null;

      try {
        object = JSON.parse(string);
        this.push(object);
        next();
      } catch(error) {
        next({
          error: 'Unable to parse string with JSON.parse()'
          Error: error
        });
      }
    }
  });
}

// the through2 way:
// Note: this way requires splitting incoming string on newlines via another
//       transform piped to this one, or, done manually in your function.
var thru = require('through2')
function builder2(options) {
  return thru(function (data, encoding, next) {
    // same processing as above in builder1.
  });
}

// the transforming way:
// Note: (module is a function which accepts build options)
var transform = require('transforming')()
var builder3 = function(options) {
  // simple case of transforming a newline delimited string into an object
  return transform.splitStringToObject(JSON.parse);
  // OR: long form without making use of defaults or convenience functions:
  return transform.split('\n').string('utf8').toObject(JSON.parse);
}
```

## MIT License
