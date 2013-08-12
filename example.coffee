Etcd = require './src/index.coffee'

c = new Etcd

## Basic operations

# Set a value
c.set "/key", "value", (err, val) ->
	console.log err, val

# Get a value
c.get "/key", (err, val) ->
	console.log err, val

# Delete a value
c.del "/key", (err, val) ->
	console.log err, val

# Set with expiry (time to live)
c.setTTL "/key", "value", 5, (err, val) ->
	console.log err, val


## Atomic setting (test and set)

c.set "/key", "value", (err, val) ->
	console.log err, val

# Setting key to value2 if value is value, success
c.setTest "/key", "value2", "value", (err, val) ->
	console.log err, val

# Setting key to value2 if value is value, failure
c.setTest "/key", "value2", "value", (err, val) ->
	console.log err, val


## Watch key

c.watch "/key3", (err, val) ->
	console.log err, val

c.set "/key3", "value3", (err, val) ->
	console.log err, val

# Watch a key from a specific index
c.watchIndex "/key3", 5, (err, val) ->
	console.log err, val


## Directory listing

# Set two keys with path
c.set "/dir/key1", "value1", (err, val) ->
	console.log err, val
c.set "/dir/key2", "value2", (err, val) ->
	console.log err, val

# List a key path
c.get "/dir/", (err, val) ->
	console.log err, val


## Other

# List machines in the etcd cluster
c.machines (err, val) ->
	console.log err, val

# Get the leader of the cluster
c.leader (err, val) ->
	console.log err, val


