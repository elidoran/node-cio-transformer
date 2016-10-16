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

Accepts the actual transform instance, a function to build the transform, or a string it can provide to `require()` to get an instance or builder function.

Note: A server should (very likely) use builder functions to make a new transform for each connection.

```javascript
// get the module's builder function
var buildCio = require('cio');

// pass this module's name to the core module: `cio` as a plugin
var cio = buildCio({
  // can specify many plugins in this array
  plugins: [ '@cio/transformer' ]
});

//  OR: provide options for a plugin too:
var cio = buildCio({
  plugins: [
    { plugin: '@cio/transformer', options: {some: 'options'} }
  ]
});

// could alternatively do any of the following:

// pass the plugin info to the `cio.use()` function
cio.use('@cio/transformer');

//  OR: and with some plugin options
cio.use('@cio/transformer', { some: 'options' });

//  OR: provide the function to use()
var fn = require('@cio/transformer');
cio.use(fn);

//  OR: provide the function with options
cio.use(fn, { some: 'options' });


// now make a client

// get an instance of our transform (or a function which builds the transform)
var someTransform = getSomeTransform();

// specify the transform in the options (or specify an array of them)
var options = { transform: someTransform };
// OR: use an array for multiple transforms
var options = { transform: [ someTransform ] };

// then create a client
client = cio.client(options);

// the result is a client socket created by `net.connect()`
// when it connects it will do:
// client.pipe(theTransform).pipe(client)

// Note: specify multiple transforms and they will be piped in the order given.

// Note: see module `cio` for more on its options

// Do the same with cio.server(...) for server side connection setup
```

## Usage: Specify string, function, or transform

Each transform specified may be an instance of a transform or a function which returns a transform.

Also, they may be a string which can be passed to `require()` to get a function or a transform.

Note, they may be mixed.

```javascript
// assume we've already created the `cio` instance as above.

// some different ways to specify it
var transformFromRequire = 'some-module'        // string
  , transformFromFunction = someBuilderFunction // function
  , transformInstance = getSomeTransform();     // transform

// create options with the transforms
var options = {
  transform: [
    // note, they will be piped in the order specified here
    transformFromRequire
    , transformFromFunction
    , transformInstance
  ]
};

// create the connection
var client = cio.client(options);
//  OR, for a server:
var server = cio.server(options);

// the `transformFromRequire` string will be passed to a require() call
// expecting to receive a builder function which will accept the `options`
// passed to client()/server() and return a transform instance.

// the `transformFromFunction` should be a function which accepts the `options`
// provided to client()/server() and builds a transform.

// the `transformInstance` is used as is.

// when the client connects, or when a new server connection is made, it will
// pipe the connection into the first transform, then each transform in order,
// then back to the connection.
// for a client() connection this is done once.
// for a server() it will be done for *each* new connection. This means using
// a builder function is important so it builds a new transform instance for
// each new connection.
// Note: a transform specified by a string will be require()'d only once. its
// result will be reused.
```

## Build Transform

There are multiple ways to build a Transform.

1. Use the standard methods described in Node's `stream` [documentation](https://nodejs.org/docs/latest/api/stream.html#stream_api_for_stream_implementers) (Note, this link is for the latest Node, be sure to check for the version you're using).
2. Use a helper module such as [through](https://www.npmjs.com/package/through) or [through2](https://www.npmjs.com/package/through2)
3. Use a builder module [transforming](https://www.npmjs.com/package/transforming) (disclaimer: I made this module...)

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
