# node-etcd

A nodejs library for [etcd](http://github.com/coreos/etcd), written in coffee-script.

[![NPM](https://nodei.co/npm/node-etcd.png)](https://nodei.co/npm/node-etcd/)

Travis-CI: [![Build Status](https://travis-ci.org/stianeikeland/node-etcd.png?branch=master)](https://travis-ci.org/stianeikeland/node-etcd)

## Install

```
$ npm install node-etcd
```

There also exist an experimental branch with support for etcd v2, to use it try:

```
$ npm install node-etcd --tag beta
```

## Changes

- 2.0.2 - Mkdir and rmdir.
- 2.0.1 - Watch, delete and stats now use new v2 api. Added testAndSet convenience method.
- 2.0.0 - Basic support for etcd protocol v2. set, get, del now supports options.
- 0.6.0 - Watcher now emits 'error' on invalid responses.

## Basic usage

```javascript
Etcd = require('node-etcd');
etcd = new Etcd();
etcd.set("key", "value");
etcd.get("key", console.log);
```

## Methods

### Etcd([host = 127.0.0.1], [port = '4001'], [ssloptions])

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

### .watcher(key, [index])

Returns an eventemitter for watching for changes on a key

```javascript
watcher = etcd.watcher("key");
watcher.on("change", console.log);
```

Signals:
- `change` - emitted on value change
- `reconnect` - emitted on reconnect
- `error` - emitted on invalid content

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

