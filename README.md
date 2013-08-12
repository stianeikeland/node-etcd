# node-etcd

A work in progress nodejs library for [etcd](http://github.com/coreos/etcd)

Only supports simple get, set, delete operations for now.

## Example

```coffeescript
# Example in coffee-script

EtcdClient = require 'node-etcd'

c = new EtcdClient

c.set "/key", "value", (err, val) ->
	console.log err, val

c.get "/key", (err, val) ->
	console.log err, val
```
