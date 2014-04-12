{EventEmitter} = require 'events'

# A eventemitter for watching changes on a given key for etcd.
# Emits:
# 	'change' - on value change
# 	'reconnect' - on errors/timeouts
# 	'<etcd action>' - the etcd action that triggered the watcher (set, delete, etc)
#
# 	Automatically reconnects and backs off on errors.
#
class Watcher extends EventEmitter

	constructor: (@etcd, @key, @index = null, @options = {}) ->
		@stopped = false
		@retryAttempts = 0
		@_watch()

	stop: () =>
		@stopped = true
		@request.abort()
		@emit 'stop', "Watcher for '#{@key}' aborted."

	_watch: () =>
		if @index is null
			@request = @etcd.watch @key, @options, @_respHandler
		else
			@request = @etcd.watchIndex @key, @index, @options, @_respHandler

	_respHandler: (err, val, headers) =>

		return if @stopped

		if err
			error = new Error 'Connection error, reconnecting.'
			error.error = err
			error.reconnectCount = @retryAttempts
			@emit 'reconnect', error
			@_retry()

		else if val?.node?.modifiedIndex?
			@retryAttempts = 0
			@index = val.node.modifiedIndex + 1
			@emit 'change', val, headers
			@emit val.action, val, headers if val.action?
			@_watch()

		else
			error = new Error 'Received unexpected response'
			error.response = val;
			@emit 'error', error
			@_watch()

	_retry: () =>
		setTimeout @_watch, 500 * @retryAttempts
		@retryAttempts++

exports = module.exports = Watcher
