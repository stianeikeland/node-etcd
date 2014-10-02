# node-etcd

A nodejs library for [etcd](http://github.com/coreos/etcd), written in coffee-script.

[![NPM](https://nodei.co/npm/node-etcd.png?downloads=true&stars=true)](https://nodei.co/npm/node-etcd/)

Travis-CI: [![Build Status](https://travis-ci.org/stianeikeland/node-etcd.png?branch=master)](https://travis-ci.org/stianeikeland/node-etcd)

## Install

```
$ npm install node-etcd
```

For the older etcd v1 api, please use the 0.6.x branch

```
# Older version for v1 API:
$ npm install node-etcd@0.6.1
```

## Changes

- 2.1.5 - Watcher: try to resync if etcd reports cleared index
- 2.1.4 - Don't wait before reconnecting if Etcd server times out our watcher.
- 2.1.3 - Etcd sends an empty response on timeout in recent versions. Parsing
  the empty message caused watcher to emit error. Now it reconnects instead.
- 2.1.2 - Exponential backoff (retry), fix spinning reconnect on error. (@ptte)
- 2.1.1 - Increase request pool.maxSockets to 100
- 2.1.0 - Use proper error objects instead of strings for errors.
- 2.0.10 - Fix error in documentation
- 2.0.9 - Added .post() alias of .create(). Added .compareAndDelete() (for etcd v0.3.0)
- 2.0.8 - Watchers can be canceled. In-order keys using #create(). Raw requests using #raw().
- 2.0.7 - Avoid calling callback if callback not given.
- 2.0.6 - Refactoring, fix responsehandler error.
- 2.0.5 - Undo use of 'x-etcd-index', this refers to global state.
- 2.0.4 - Use 'x-etcd-index' for index when watching a key.
- 2.0.3 - Watcher supports options. Watcher emits etcd action type.
- 2.0.2 - Mkdir and rmdir. Fix watcher for v2 api.
- 2.0.1 - Watch, delete and stats now use new v2 api. Added testAndSet convenience method.
- 2.0.0 - Basic support for etcd protocol v2. set, get, del now supports options.
- 0.6.1 - Fixes issue #10, missing response caused error when server connection failed / server responded incorrectly.
- 0.6.0 - Watcher now emits 'error' on invalid responses.

## Basic usage

```javascript
Etcd = require('node-etcd');
etcd = new Etcd();
etcd.set("key", "value");
etcd.get("key", console.log);
```

## Methods

### Etcd([host = '127.0.0.1'], [port = '4001'], [ssloptions])

Create a new etcd client

```javascript
etcd = new Etcd();
etcd = new Etcd('127.0.0.1', '4001');
```

### .set(key, value = null, [options], [callback])

Set key to value, or create key/directory.

```javascript
etcd.set("key");
etcd.set("key", "value");
etcd.set("key", "value", console.log);
etcd.set("key", "value", { ttl: 60 }, console.log);
```

Available options include:

- `ttl` (time to live in seconds)
- `prevValue` (previous value, for compare and swap)
- `prevExist` (existance test, for compare and swap)
- `prevIndex` (previous index, for compare and swap)

Will create a directory when used without value (value=null): `etcd.set("directory/");`

### .compareAndSwap(key, value, oldvalue, [options], [callback])

Convenience method for test and set (set with {prevValue: oldvalue})

```javascript
etcd.compareAndSwap("key", "newvalue", "oldvalue");
etcd.compareAndSwap("key", "newValue", "oldValue", options, console.log);
```

Alias: `.testAndSet()`

### .get(key, [options], [callback])

Get a key or path.

```javascript
etcd.get("key", console.log);
etcd.get("key", { recursive: true }, console.log);
```

Available options include:

- `recursive` (bool, list all values in directory recursively)
- `wait` (bool, wait for changes to key)
- `waitIndex` (wait for changes after given index)

### .del(key, [options], [callback])

Delete a key or path

```javascript
etcd.del("key");
etcd.del("key", console.log);
etcd.del("key/", { recursive: true }, console.log);
```

Available options include:

- `recursive` (bool, delete recursively)

Alias: `.delete()`

### .compareAndDelete(key, oldvalue, [options], [callback])

Convenience method for test and delete (delete with {prevValue: oldvalue})

```javascript
etcd.compareAndDelete("key", "oldvalue");
etcd.compareAndDelete("key", "oldValue", options, console.log);
```

Alias: `.testAndDelete()`

### .mkdir(dir, [options], [callback])

Create a directory

```javascript
etcd.mkdir("dir");
etcd.mkdir("dir", console.log);
etcd.mkdir("dir/", options, console.log);
```

### .rmdir(dir, [options], [callback])

Remove a directory

```javascript
etcd.rmdir("dir");
etcd.rmdir("dir", console.log);
etcd.rmdir("dir/", { recursive: true }, console.log);
```

Available options include:

- `recursive` (bool, delete recursively)

### .create(path, value, [options], [callback])

Atomically create in-order keys.

```javascript
etcd.create("queue", "first")
etcd.create("queue", "next", console.log)
```

Alias: `.post()`

### .watch(key, [options], [callback])

This is a convenience method for get with `{wait: true}`.

```javascript
etcd.watch("key");
etcd.watch("key", console.log);
```

### .watchIndex(key, index, [options], callback)

This is a convenience method for get with `{wait: true, waitIndex: index}`.

```javascript
etcd.watchIndex("key", 7, console.log);
```

### .watcher(key, [index], [options])

Returns an eventemitter for watching for changes on a key

```javascript
watcher = etcd.watcher("key");
watcher.on("change", console.log);
watcher2 = etcd.watcher("key", null, {recursive: true});
watcher2.on("error", console.log);
```

You can cancel a watcher by calling `.stop()`.

Signals:
- `change` - emitted on value change
- `reconnect` - emitted on reconnect
- `error` - emitted on invalid content
- `<etcd action>` - the etcd action that triggered the watcher (ex: set, delete).
- `stop` - watcher was canceled.
- `resync` - watcher lost sync (etcd clear and outdated the index).

### .raw(method, key, value, options, callback)

Bypass the API and do raw queries.
Method must be one of: PUT, GET, POST, PATCH, DELETE

```javascript
etcd.raw("GET", "v2/stats/leader", null, {}, callback)
etcd.raw("PUT", "v2/keys/key", "value", {}, callback)
```

Remember to provide the full path, without any leading '/'

### .machines(callback)

Returns information about etcd nodes in the cluster

```javascript
etcd.machines(console.log);
```

### .leader(callback)

Return the leader in the cluster

```javascript
etcd.leader(console.log);
```

### .leaderStats(callback)

Return statistics about cluster leader

```javascript
etcd.leaderStats(console.log);
```

### .selfStats(callback)

Return statistics about connected etcd node

```javascript
etcd.selfStats(console.log);
```

## SSL support

Pass etcdclient a dictionary containing ssl options, check out http://nodejs.org/api/https.html#https_https_request_options_callback

```javascript
fs = require('fs');

sslopts = {
	ca: [ fs.readFileSync('ca.pem') ],
	cert: fs.readFileSync('cert.pem'),
	key: fs.readFileSync('key.pem')
};

etcdssl = new Etcd('localhost', '4001', sslopts);
```

## FAQ:

- Are there any order of execution guarantees when doing multiple requests without using callbacks?
    - No, order of execution is up to NodeJS and the network. Requests run from a connection pool, meaning that if one request is delayed for some reason they'll arrive at the server out of order. Use callbacks (and maybe even a nice [async](https://github.com/caolan/async) callback handling library for convenient syntax) if ordering is important to prevent race conditions.
