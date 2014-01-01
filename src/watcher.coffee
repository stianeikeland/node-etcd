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
		@retryAttempts = 0
		@_watch()

	_watch: () =>
		if @index is null
			@etcd.watch @key, @options, @_respHandler
		else
			@etcd.watchIndex @key, @index, @options, @_respHandler

	_respHandler: (err, val, headers) =>

		if err
			@emit 'reconnect', { error: err, reconnectcount: @retryAttempts }
			@_retry()

		else if val? and headers?['x-etcd-index']?
			@retryAttempts = 0
			@index = parseInt(headers['x-etcd-index']) + 1
			@emit 'change', val, headers
			@emit val.action, val, headers if val.action?
			@_watch()

		else
			@emit 'error', "Received unexpected response '#{val}'"
			@_watch()

	_retry: () =>
		setTimeout @_watch, 500 * @retryAttempts
		@retryAttempts++

exports = module.exports = Watcher
