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

## Usage

```coffeescript
# Coffee-script examples:
Etcd = require 'node-etcd'
c = new Etcd

# Set a value
c.set "/key", "value", (err, val) ->
	console.log err, val

# Get a value
c.get "/key", (err, val) ->
	console.log err, val

# Delete a value
c.del "/key", (err, val) ->
	console.log err, val

# Watch a value (wait for a single value change)
c.watch "/key", (err, val) ->
	console.log err, val

# Watcher retuns an eventemitter for continuously watching changes,
# it also handles reconnect on error, etc..
w = c.watcher '/key'

w.on 'change', console.log
w.on 'reconnect', console.log

# Set with expiry (time to live)
c.setTTL "/key", "value", 5, (err, val) ->
	console.log err, val

# Atomic setting (test and set)
c.setTest "/key", "new value", "old value", (err, val) ->
	console.log err, val

# List machines in the etcd cluster
c.machines (err, val) ->
	console.log err, val

# Get the leader of the cluster
c.leader (err, val) ->
	console.log err, val

# Statistics (leader and self)
c.leaderStats (err, val) -> console.log err, val
c.selfStats (err, val) -> console.log err, val

# SSL Support
# Pass etcd a dictionary containing ssl options
# Check out http://nodejs.org/api/https.html#https_https_request_options_callback
fs = require 'fs'

sslopts =
	ca: [ fs.readFileSync 'ca.pem' ]
	cert: fs.readFileSync 'cert.pem'
	key: fs.readFileSync 'key.pem'

etcdssl = new Etcd 'localhost', '4001', sslopts

etcdssl.get 'key', console.log

```
