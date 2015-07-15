# mongodb-log [![][npm_img]][npm_url] [![][travis_img]][travis_url] [![][coverage_img]][coverage_url] [![][gitter_img]][gitter_url]

Normalize MongoDB log entries into objects that make sense.

## Example

```javascript
var parse = require('mongodb-log');
var line = 'Wed Mar 12 14:42:31 [initandlisten] db version v2.5.6-pre-';
console.log('`' + line + '` → ', JSON.stringify(parse(line), null, 2));

// Prints out:
//
//   `Wed Mar 12 14:42:31 [initandlisten] db version v2.5.6-pre-` →  [
//     {
//       "timestamp": "Wed Mar 12 14:42:31",
//       "message": "db version v2.5.6-pre-",
//       "line": "Wed Mar 12 14:42:31 [initandlisten] db version v2.5.6-pre-",
//       "thread": "initandlisten",
//       "timestamp_format": "ctime-pre2.4",
//       "_id": "initandlisten:Wed Mar 12 14:42:31",
//       "stats": {}
//     }
//   ]
```

```javascript
var parse = require('mongodb-log');
var lines = [
  '2014-05-16T10:39:00.938-0400 [conn611] end connection 127.0.0.1:57499 (22 connections now open)',
  '2014-05-16T10:43:24.840-0400 [clientcursormon] mem (MB) res:9 virt:3514',
  '2014-05-16T10:43:24.840-0400 [clientcursormon]  mapped (incl journal view):960',
  '2014-05-16T10:43:24.840-0400 [clientcursormon]  connections:22',
  '2014-05-16T10:48:24.926-0400 [clientcursormon] mem (MB) res:9 virt:3514',
  '2014-05-16T10:48:24.926-0400 [clientcursormon]  mapped (incl journal view):960',
  '2014-05-16T10:48:24.926-0400 [clientcursormon]  connections:22'
];
console.log('lots of lines → ', JSON.stringify(parse(lines), null, 2));

// Prints out:
//
//   lots of lines →  [
//     [
//       {
//         "timestamp": "2014-05-16T10:39:00.938-0400",
//         "message": "end connection 127.0.0.1:57499 (22 connections now open)",
//         "line": "2014-05-16T10:39:00.938-0400 [conn611] end connection 127.0.0.1:57499 (22 connections now open)",
//         "thread": "conn611",
//         "timestamp_format": "iso8601-local",
//         "connection_id": "conn611",
//         "_id": "conn611:2014-05-16T10:39:00.938-0400",
//         "stats": {}
//       },
//       {
//         "timestamp": "2014-05-16T10:43:24.840-0400",
//         "message": "mem (MB) res:9 virt:3514",
//         "line": "2014-05-16T10:43:24.840-0400 [clientcursormon] mem (MB) res:9 virt:3514",
//         "thread": "clientcursormon",
//         "timestamp_format": "iso8601-local",
//         "_id": "clientcursormon:2014-05-16T10:43:24.840-0400",
//         "stats": {}
//       },
//       {
//         "timestamp": "2014-05-16T10:43:24.840-0400",
//         "message": " mapped (incl journal view):960",
//         "line": "2014-05-16T10:43:24.840-0400 [clientcursormon]  mapped (incl journal view):960",
//         "thread": "clientcursormon",
//         "timestamp_format": "iso8601-local",
//         "_id": "clientcursormon:2014-05-16T10:43:24.840-0400",
//         "stats": {}
//       },
//       {
//         "timestamp": "2014-05-16T10:43:24.840-0400",
//         "message": " connections:22",
//         "line": "2014-05-16T10:43:24.840-0400 [clientcursormon]  connections:22",
//         "thread": "clientcursormon",
//         "timestamp_format": "iso8601-local",
//         "_id": "clientcursormon:2014-05-16T10:43:24.840-0400",
//         "stats": {}
//       },
//       {
//         "timestamp": "2014-05-16T10:48:24.926-0400",
//         "message": "mem (MB) res:9 virt:3514",
//         "line": "2014-05-16T10:48:24.926-0400 [clientcursormon] mem (MB) res:9 virt:3514",
//         "thread": "clientcursormon",
//         "timestamp_format": "iso8601-local",
//         "_id": "clientcursormon:2014-05-16T10:48:24.926-0400",
//         "stats": {}
//       },
//       {
//         "timestamp": "2014-05-16T10:48:24.926-0400",
//         "message": " mapped (incl journal view):960",
//         "line": "2014-05-16T10:48:24.926-0400 [clientcursormon]  mapped (incl journal view):960",
//         "thread": "clientcursormon",
//         "timestamp_format": "iso8601-local",
//         "_id": "clientcursormon:2014-05-16T10:48:24.926-0400",
//         "stats": {}
//       },
//       {
//         "timestamp": "2014-05-16T10:48:24.926-0400",
//         "message": " connections:22",
//         "line": "2014-05-16T10:48:24.926-0400 [clientcursormon]  connections:22",
//         "thread": "clientcursormon",
//         "timestamp_format": "iso8601-local",
//         "_id": "clientcursormon:2014-05-16T10:48:24.926-0400",
//         "stats": {}
//       }
//     ]
//   ]
```

```javascript
var parse = require('../');
console.log('i even understand events! → ', JSON.stringify(parse(
  '2014-05-16T10:50:13.450-0400 [initandlisten] recover : no journal files present, no recovery needed',
  '2014-05-16T10:50:13.579-0400 [initandlisten] waiting for connections on port 27017'
), null, 2));

// Prints out:
//
//   i even understand events! →  [
//     {
//       "timestamp": "2014-05-16T10:50:13.450-0400",
//       "message": "recover : no journal files present, no recovery needed",
//       "line": "2014-05-16T10:50:13.450-0400 [initandlisten] recover : no journal files present, no recovery needed",
//       "thread": "initandlisten",
//       "timestamp_format": "iso8601-local",
//       "_id": "initandlisten:2014-05-16T10:50:13.450-0400",
//       "stats": {}
//     },
//     {
//       "timestamp": "2014-05-16T10:50:13.579-0400",
//       "message": "waiting for connections on port 27017",
//       "line": "2014-05-16T10:50:13.579-0400 [initandlisten] waiting for connections on port 27017",
//       "thread": "initandlisten",
//       "event": {
//         "name": "ready",
//         "data": {
//           "port": 27017
//         }
//       },
//       "timestamp_format": "iso8601-local",
//       "_id": "initandlisten:2014-05-16T10:50:13.579-0400",
//       "stats": {}
//     }
//   ]
```

```javascript
var parse = require('mongodb-log');
var fs = require('fs');
var es = require('event-stream');

fs.createReadStream('/var/log/mongodb/mongod.log')
  .pipe(es.split('\n'))
  .pipe(parse())
  .pipe(fs.createWriteStream('/var/log/mongodb/mongod.json'));
```

## License

Apache 2.0

[travis_img]: https://secure.travis-ci.org/mongodb-js/log.svg?branch=master
[travis_url]: https://travis-ci.org/mongodb-js/log
[npm_img]: https://img.shields.io/npm/v/mongodb-log.svg
[npm_url]: https://www.npmjs.org/package/mongodb-log
[coverage_img]: https://coveralls.io/repos/mongodb-js/log/badge.svg?branch=master
[coverage_url]: https://coveralls.io/r/mongodb-js/log
[gitter_img]: https://badges.gitter.im/Join%20Chat.svg
[gitter_url]: https://gitter.im/mongodb-js/mongodb-js
