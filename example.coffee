EtcdClient = require './src/index.coffee'

c = new EtcdClient

c.del "/key", (err, val) ->
	console.log err, val

c.set "/key", "value", (err, val) ->
	console.log err, val

c.setTest "/key", "value2", "value", (err, val) ->
	console.log err, val

c.setTest "/key", "value2", "value", (err, val) ->
	console.log err, val

c.setTTL "/key", "value", 5, (err, val) ->
	console.log err, val

c.get "/key", (err, val) ->
	console.log err, val
