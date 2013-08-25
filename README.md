# node-etcd

A nodejs library for [etcd](http://github.com/coreos/etcd), written in coffee-script.

[![NPM](https://nodei.co/npm/node-etcd.png)](https://nodei.co/npm/node-etcd/)

Travis-CI: [![Build Status](https://travis-ci.org/stianeikeland/node-etcd.png)](https://travis-ci.org/stianeikeland/node-etcd)

## Install

```
$ npm install node-etcd
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

```
