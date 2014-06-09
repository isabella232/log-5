var assert = require('assert'),
    log    = require('./..');

describe('parse', function() {
  it('should match thread', function() {
    var line = '2014-02-13T18:00:04.709-0500 [initandlisten] db version ' +
      'v2.5.6 -pre-';
    var res = log.parse(line)[0];

    assert.equal(res.thread, 'initandlisten');
  });
});