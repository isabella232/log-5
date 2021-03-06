start = line

/**
 * 2.2.5:
 *
 * Mon Aug  5 20:53:20 [conn133] end connection 10.0.0.12:52655 (2 connections now open)
 * Mon Aug  5 20:53:20 [initandlisten] connection accepted from 10.0.0.12:52665 #135 (3 connections now open)
 *
 * 2.4.11:
 *
 * Thu Oct  9 15:20:20.465 [rsStart] replSet info you may need to run replSetInitiate -- rs.initiate() in the shell -- if that is not already done
 * Thu Oct  9 15:20:20.692 [initandlisten] connection accepted from 127.0.0.1:54763 #1 (1 connection now open)
 *
 * 2.6:
 *
 * 2014-04-09T23:17:40.799-0400 [initandlisten] connection accepted from 10.0.1.135:52274 #39 (13 connections now open)
 * 2014-04-09T23:17:40.800-0400 [conn39]  authenticate db: local { authenticate: 1, nonce: "xxx", user: "__system", key: "xxx" }
 *
 * 2.7.8:
 *
 * 2014-10-31T13:00:04.258+0000 I STORAGE  [FileAllocator] done allocating datafile /Users/joleary/Documents/Support/CS-16129/data/db/local.0,  * size: 64MB,  took 0.261 secs
 * 2014-10-31T13:00:04.295+0000 I QUERY    [initandlisten] command local.$cmd command: create { create: "startup_log", size: 10485760, capped: true } ntoreturn:1 keyUpdates:0 numYields:0  reslen:37 365ms
*/

/**
 * ## Timestamp
 *
 * The timestamp is at the beginning of every log line. There are 4
 * timestamp formats that need to be supported.
 *
 * | Timestamp Format |           Example            | MongoDB Version |
 * | :--------------- | :--------------------------- | :-------------- |
 * | ctime-no-ms      | Wed Dec 31 19:00:00          | < 2.4           |
 * | ctime            | Wed Dec 31 19:00:00.000      | 2.4             |
 * | iso8601-local    | 1969-12-31T19:00:00.000+0500 | >= 2.6          |
 * | iso8601-utc      | 1970-01-01T00:00:00.000Z     | >= 2.6          |
 */
date_year = $(DIGIT DIGIT DIGIT DIGIT)
date_month "MM 01-12" = $(DIGIT DIGIT)
date_mday "DD 01-31" = $(DIGIT DIGIT)
date_day "D 1-31" = $(DIGIT)
date "YYYY-MM-DD" = $(date_year '-' date_month '-' date_mday)
abbrv_days "ddd" = 'Mon' / 'Tue' / 'Wed' / 'Thu' / 'Fri' / 'Sat' / 'Sun'
abbrv_months "MMM" = 'Jan' / 'Feb' / 'Mar' / 'Apr' / 'May' / 'Jun' / 'Jul' / 'Aug' / 'Sep' / 'Oct' / 'Nov' / 'Dec'
time_hour "HH 00-24" = $(DIGIT DIGIT)
time_minute "MM" = $(DIGIT DIGIT)
time_second "SS" = $(DIGIT DIGIT)
time_fraction "SSS" = (',' / '.') $(DIGIT+)
time_numoffset "ZZ" = ('+' / '-') time_hour (':'? time_minute)?
time_zone "Z" = 'Z' / time_numoffset
time "HH:MM:SS" = time_hour ':' time_minute ':' time_second

// describe('mongodb-log timestamp parsing', function(){
//
//  it('should parse MongoDB < 2.4.x (ctime_no_ms)', function(){
//    var val = 'Wed Dec 31 19:00:00';
//    var res = parseTimestamp(val);
//    assert.equal(res.timestamp_format, 'MMM ddd D hh:mm:ss');
//  });
ctime_no_ms
  = value:$(abbrv_days ws abbrv_months ws date_mday ws time) {
    return {
      'timestamp': value,
      // @todo: D (`1`) or DD (`01`)?
      'timestamp_format': 'MMM ddd D hh:mm:ss'
    };
  }
// it('should parse MongoDB 2.4.x (ctime)', function(){
//   var val = 'Wed Dec 31 19:00:00.000';
//   var res = parseTimestamp(val);
//   assert.equal(res.timestamp_format, 'MMM ddd D hh:mm:ss.SSS');
// });
ctime
  = value:$(abbrv_days ws abbrv_months ws date_day ws time time_fraction) {
    return {
      'timestamp': value,
      // @todo: D (`1`) or DD (`01`)?
      'timestamp_format': 'MMM ddd D hh:mm:ss.SSS'
    };
  }

// it('should parse MongoDB >= 2.6.x (iso8601-local)', function(){
//   var val = '1969-12-31T19:00:00.000+0500';
//   var res = parseTimestamp(val);
//   assert.equal(res.timestamp_format, 'YYYY-MM-DDThh:mm:ss.SSSZZ');
// });
iso8601_local
  = value:$(date "T" time time_fraction time_zone) {
    return {
      'timestamp': value,
      'timestamp_format': 'YYYY-MM-DDThh:mm:ss.SSSZZ'
    };
  }

// it('should parse MongoDB >= 2.6.x (iso8601-utc)', function(){
//   var val = '1970-01-01T00:00:00.000Z';
//   var res = parseTimestamp(val);
//   assert.equal(res.timestamp_format, 'YYYY-MM-DDThh:mm:ss.SSS\Z');
// });
iso8601_utc
  = value:$(date "T" time time_fraction time_zone) {
    return {
      'timestamp': value,
      'timestamp_format': 'YYYY-MM-DDThh:mm:ss.SSS\\Z'
    };
  }

// Reduce *all* timestamps to a single rule
timestamp
  = iso8601_utc
  / iso8601_local
  / ctime
  / ctime_no_ms
// });

/**
 * ## component
 *
 * [Source][src] [Documentation][docs]
 *
 * [src]: https://github.com/mongodb/mongo/blob/master/src/mongo/logger/log_component.cpp#L138-L151
 * [docs]: http://docs.mongodb.org/master/reference/log-messages/#components
 */
component
  = '-'
  / 'ACCESS'
  / 'COMMAND'
  / 'CONTROL'
  / 'GEO'
  / 'INDEX'
  / 'NETWORK'
  / 'QUERY'
  / 'REPL'
  / 'SHARDING'
  / 'STORAGE'
  / 'JOURNAL'
  / 'WRITE'
  / 'S2'

/**
 * ## severity
 *
 * *New in 3.0*
 *
 * [Documentation][docs]
 *
 * [docs]: http://docs.mongodb.org/master/reference/log-messages/#severity-levels

 */
severity
  = 'F'
  / 'E'
  / 'W'
  / 'I'
  / 'D'
  / 'U'

/**
 * ## context
 *
 * a.k.a. `thread`
 */

/**
 * @todo: handle thread initanlisten but conn accepted message should have connection_id
 * set instead of thread=initandlisten.
 *
 * /^connection accepted from (?:\d{1,3}\.){3}\d{1,3}:\d{1,5} #(\d*)/,
 * 'connection accepted from 127.0.0.1:52049 #700 (1 connection now open)',
 */
context_connection = '[conn' connection_id:$(DIGIT+) ']' { return { 'connection_id': parseInt(connection_id, 10) } }
context_thread = '[' thread:$([a-zA-Z]+) ']' { return { 'thread': thread } }
context = ws context_connection ws / ws context_thread ws

duration = duration:$(DIGIT+) 'ms' { return { 'duration': parseInt(duration, 10) } }

// ntoreturn:1 ntoskip:0 nscanned:0 keyUpdates:0 locks(micros) r:8457 nreturned:0 reslen:20
query_stats
  = 'ntoreturn:' to_return_count:$(DIGIT+) ws 'ntoskip:' to_skip_count:$(DIGIT+) ws 'nscanned:' scanned_count:$(DIGIT+) ws 'keyUpdates:' key_updates_count:$(DIGIT+) ws 'locks(micros) r:' read_lock_time:$(DIGIT+) ws 'nreturned:' returned_count:$(DIGIT+) ws 'reslen:' result_length:$(DIGIT+) ws {
    return {
      to_return_count: parseInt(to_return_count, 10),
      to_skip_count: parseInt(to_skip_count, 10),
      scanned_count: parseInt(scanned_count, 10),
      key_updates_count: parseInt(key_updates_count, 10),
      read_lock_time: parseInt(read_lock_time, 10),
      returned_count: parseInt(returned_count, 10),
      result_length: parseInt(result_length, 10)
    }
  }

// ntoreturn:1 keyUpdates:0 locks(micros) r:19091 reslen:208
mr_stats
  = 'ntoreturn:' to_return_count:$(DIGIT+) ws 'keyUpdates:' key_updates_count:$(DIGIT+) ws 'locks(micros) r:' read_lock_time:$(DIGIT+) ws 'reslen:' result_length:$(DIGIT+) ws {
    return {
      to_return_count: parseInt(to_return_count, 10),
      key_updates_count: parseInt(key_updates_count, 10),
      read_lock_time: parseInt(read_lock_time, 10),
      result_length: parseInt(result_length, 10)
    }
  }

// cursorid:805169450824913355 ntoreturn:0 keyUpdates:0 numYields: 1 locks(micros) r:335 nreturned:1 reslen:217
getmore_stats
  = 'cursorid:' cursor_id:$(DIGIT+) ws 'ntoreturn:' to_return_count:$(DIGIT+) ws 'keyUpdates:' key_updates_count:$(DIGIT+) ws 'numYields: ' yield_count:$(DIGIT+) ws 'locks(micros) r:' read_lock_time:$(DIGIT+) ws 'nreturned:' returned_count:$(DIGIT+) ws 'reslen:' result_length:$(DIGIT+) ws {
    return {
      cursor_id: parseInt(cursor_id, 10),
      to_return_count: parseInt(to_return_count, 10),
      key_updates_count: parseInt(key_updates_count, 10),
      yield_count: parseInt(yield_count, 10),
      read_lock_time: parseInt(read_lock_time, 10),
      returned_count: parseInt(returned_count, 10),
      result_length: parseInt(result_length, 10)
    };
  }

// idhack:1 nupdated:1 upsert:1 keyUpdates:0 locks(micros) w:24047
update_stats
  = 'idhack:' is_id_hack:$(DIGIT+) ws 'nupdated:' updated_count:$(DIGIT+) ws 'upsert:' is_upsert:$(DIGIT+) ws 'keyUpdates:' key_updates_count:$(DIGIT+) ws 'locks(micros) w:' write_lock_time:$(DIGIT+) ws {
    return {
      is_id_hack: Boolean(parseInt(is_id_hack, 10)),
      updated_count: parseInt(updated_count, 10),
      is_upsert: Boolean(parseInt(is_upsert, 10)),
      key_updates_count: parseInt(key_updates_count, 10),
      write_lock_time: parseInt(write_lock_time, 10)
    };
  }

ns = ws database:$([a-zA-Z]+) '.' collection:$([a-zA-Z\.]+) ws {
    return {
      'database': database,
      'collection': collection
    };
  }

message = chars:char* {
  return chars.join('');
}

line_before_30
  = ts:timestamp context:context message:message {
    return {
      'timestamp': ts.timestamp,
      'thread': context.thread,
      'connection_id': context.connection_id,
      'message': message
    };
  }


getmore_before_30
  = ts:timestamp context:context 'getmore' ns:ns 'query:' query:JSON_text stats:getmore_stats duration:duration {
    return {
      'template': 'getmore_before_30',
      'operation': 'GETMORE',
      'timestamp': ts.timestamp,
      'timestamp_format': ts.timestamp_format,
      'thread': context.thread,
      'connection_id': context.connection_id,
      'database': ns.database,
      'collection': ns.collection,
      'duration': duration,
      'query': query.$query,
      'sort': query.$orderby,
      'stats': stats,
      'duration': duration.duration
    };
  }

query_before_30
  = ts:timestamp context:context 'query' ns:ns 'query:' query:JSON_text stats:query_stats duration:duration {
    return {
      'template': 'query_before_30',
      'operation': 'QUERY',
      'timestamp': ts.timestamp,
      'timestamp_format': ts.timestamp_format,
      'thread': context.thread,
      'connection_id': context.connection_id,
      'database': ns.database,
      'collection': ns.collection,
      'duration': duration,
      'query': query.$query,
      'sort': query.$orderby,
      'stats': stats,
      'duration': duration.duration
    };
  }

mr_before_30
  = ts:timestamp context:context 'command' ws database:$([a-zA-Z]+) ws '.$cmd command:' spec:JSON_text stats:mr_stats duration:duration {
    return {
      'template': 'mr_before_30',
      'operation': 'MAPREDUCE',
      'timestamp': ts.timestamp,
      'timestamp_format': ts.timestamp_format,
      'thread': context.thread,
      'connection_id': context.connection_id,
      'database': database,
      'collection': spec.mapreduce,
      'map': spec.map,
      'reduce': spec.reduce,
      'query': spec.$query,
      'stats': stats,
      'duration': duration.duration
    };
  }

update_before_30
  = ts:timestamp context:context 'update' ns:ns 'query:' spec:JSON_text 'update:' update:JSON_text stats:update_stats duration:duration {
    return {
      'template': 'update_before_30',
      'operation': 'UPDATE',
      'timestamp': ts.timestamp,
      'timestamp_format': ts.timestamp_format,
      'thread': context.thread,
      'connection_id': context.connection_id,
      'database': ns.database,
      'collection': ns.collection,
      'query': spec,
      'update': update,
      'stats': stats,
      'duration': duration.duration
    };
  }

// Thu Mar  6 13:09:01.670 [signalProcessingThread] error removing journal files boost::filesystem::directory_iterator::construct: No such file or directory: "/Users/tr/Documents/tmp/data/db/journal"
error_removing_journal
  = ts:timestamp context:context 'error removing journal files boost::filesystem::directory_iterator::construct: No such file or directory: "' path:PATH '"'{
    return {
      timestamp: ts.timestamp,
      thread: context.thread,
      event: {
        name: 'error',
        message: 'error removing journal files',
        path: path
      }
    };
  }

error_couldnt_remove_journal
  = ts:timestamp context:context "error couldn't remove journal file during shutdown boost::filesystem::directory_iterator::construct: No such file or directory: " quotation_mark path:PATH quotation_mark {
    return {
      timestamp: ts.timestamp,
      thread: context.thread,
      event: {
        name: 'error',
        message: 'could not remove journal file',
        path: path
      }
    };
  }

// shutdown failed with exception
shutdown_failed
  = ts:timestamp ws 'shutdown failed with exception' {
    return {
      timestamp: ts.timestamp,
      event: {
        name: 'error',
        message: 'shutdown failed with exception'
      }
    };
  }

exit_event
  = ts:timestamp ws 'dbexit: really exiting now'
  / ts:timestamp ws 'dbexit: ' {
    return {
      timestamp: ts.timestamp,
      event: {
        name: 'exit'
      }
    }
  }

options_dump
  = ts:timestamp context:context 'options:' options:JSON_text {
    return {
      timestamp: ts.timestamp,
      thread: context.thread,
      options: options
    };
  }


// 2014-06-21T00:11:22.656+0000 [conn517] command admin.$cmd command: replSetHeartbeat { replSetHeartbeat: "mmsconfig1", v: 45, pv: 1, checkEmpty: false, from: "mms-db-3.nj1.10gen.cc:27500", fromId: 8 } ntoreturn:1 keyUpdates:0 numYields:0  reslen:208 0ms
replset_heartbeat
  = ts:timestamp context:context 'command admin.$cmd command: replSetHeartbeat' spec:JSON_text 'ntoreturn:' to_return_count:$(DIGIT+) ws 'keyUpdates:' key_updates_count:$(DIGIT+) ws 'numYields:' yield_count:$(DIGIT+) ws ws 'reslen:'result_length:$(DIGIT+) ws duration:duration {
    return {
      'template': 'replset_heartbeat',
      'operation': 'REPLSET-HEARTBEAT',
      'timestamp': ts.timestamp,
      'timestamp_format': ts.timestamp_format,
      'thread': context.thread,
      'connection_id': context.connection_id,
      'stats': {
        to_return_count: parseInt(to_return_count, 10),
        key_updates_count: parseInt(key_updates_count, 10),
        yield_count: parseInt(yield_count, 10),
        result_length: parseInt(result_length, 10)
      },
      spec: spec,
      'duration': duration.duration
    };
  }

replset_events
  = replset_heartbeat

errors "error events"
  = error_removing_journal
  / error_couldnt_remove_journal
  / shutdown_failed

events
  = errors
  / exit_event
  / options_dump
  / replset_events

PATH = $([a-zA-Z0-9\$\.\_/]+)

line
  = query_before_30
  / mr_before_30
  / getmore_before_30
  / update_before_30
  / events
  / line_before_30

line_30
  = ts:timestamp ws severity:severity ws component:component context:context message:message {
    return {
      'timestamp': ts.timestamp,
      'timestamp_format': ts.timestamp_format,
      'severity': severity,
      'component': component,
      'thread': context.thread,
      'connection_id': context.connection_id,
      'message': message.join('')
    };
  }

/**
 * [json.pegjs](https://github.com/pegjs/pegjs/blob/master/examples/json.pegjs)
 */
JSON_text "json value"
   = ws value:value ws { return value; }

 begin_array     = ws "[" ws
 begin_object    = ws "{" ws
 end_array       = ws "]" ws
 end_object      = ws "}" ws
 name_separator  = ws ":" ws
 value_separator = ws "," ws
 value
   = false
   / null
   / true
   / object
   / array
   / number
   / json_string

 false = "false" { return false; }
 null  = "null"  { return null;  }
 true  = "true"  { return true;  }

/* ----- 4. Objects ----- */

object "json object"
 = begin_object
   members:(
     first:member
     rest:(value_separator m:member { return m; })*
     {
       var result = {}, i;

       result[first.name] = first.value;

       for (i = 0; i < rest.length; i++) {
         result[rest[i].name] = rest[i].value;
       }

       return result;
     }
   )?
   end_object
   { return members !== null ? members: {}; }

member
 = name:json_string name_separator value:value {
     return { name: name, value: value };
   }

/* ----- 5. Arrays ----- */

array "json array"
 = begin_array
   values:(
     first:value
     rest:(value_separator v:value { return v; })*
     { return [first].concat(rest); }
   )?
   end_array
   { return values !== null ? values : []; }
   number "number"
     = minus? int frac? exp? { return parseFloat(text()); }


ws "whitespace" = [ \t\n\r]*
decimal_point = '.'
digit1_9      = [1-9]
e             = [eE]
exp           = e (minus / plus)? DIGIT+
frac          = decimal_point DIGIT+
int           = zero / (digit1_9 DIGIT*)
minus         = '-'
plus          = '+'
zero          = '0'
json_string "json string"
  = quotation_mark chars:char* quotation_mark { return chars.join(""); }
  / chars:[a-zA-Z0-9\$\.\_]* {return chars.join("");}

string "string"
  = chars:char* { return chars.join(""); }

char
  = unescaped
  / escape
    sequence:(
        '"'
      / "\\"
      / "/"
      / "b" { return "\b"; }
      / "f" { return "\f"; }
      / "n" { return "\n"; }
      / "r" { return "\r"; }
      / "t" { return "\t"; }
      / "u" digits:$(HEXDIG HEXDIG HEXDIG HEXDIG) {
          return String.fromCharCode(parseInt(digits, 16));
        }
    )
    { return sequence; }


escape         = "\\"
quotation_mark = '"'
unescaped      = [\x20-\x21\x23-\x5B\x5D-\u10FFFF]

// Core ABNF Rules
DIGIT = [0-9]
HEXDIG = [0-9a-f]i
