request = require 'request'
_       = require 'underscore'
Watcher = require './watcher'
HttpsAgent = (require 'https').Agent

class Etcd

	# Constructor, set etcd host and port.
	# For https: provide {ca, crt, key} as sslopts.
	constructor: (@host = '127.0.0.1', @port = '4001', @sslopts = null) ->

	# Get value for given key
	get: (key, callback) ->
		opt = @_prepareOpts "keys/" + @_stripSlashPrefix(key)
		request.get opt, @_responseHandler callback

	# Set key to value
	set: (key, value, callback) ->
		@setCustom key, value, {}, callback

	# Set key to value with expirey
	setTTL: (key, value, ttl, callback) ->
		@setCustom key, value, {ttl: ttl}, callback

	# Atomic test and set value
	setTest: (key, value, prevValue, callback) ->
		@setCustom key, value, {prevValue: prevValue}, callback

	# Atomic test and set value with ttl
	setTestTTL: (key, value, prevValue, ttl, callback) ->
		@setCustom key, value, {prevValue: prevValue, ttl: ttl}, callback

	# Set key to value with exta options (ttl, prevValue, etc)
	setCustom: (key, value, extraopts, callback) ->
		opt = @_prepareOpts "keys/" + @_stripSlashPrefix(key)

		_.extend opt, {
			form: { value: value }
		}

		if extraopts?
			_.extend opt.form, extraopts

		@_postRedirectHandler opt, @_responseHandler callback

	# Delete given key
	del: (key, callback) ->
		opt = @_prepareOpts "keys/" + @_stripSlashPrefix(key)
		request.del opt, @_responseHandler callback

	# Watch for value changes on a key
	watch: (key, callback) ->
		opt = @_prepareOpts "watch/" + @_stripSlashPrefix(key)
		request.get opt, @_responseHandler callback

	# Watch for value changes on a key since a specific index
	watchIndex: (key, index, callback) ->
		@watchCustom key, {index: index}, callback

	# Watch with custom options
	watchCustom: (key, opts, callback) ->
		opt = @_prepareOpts "watch/" + @_stripSlashPrefix(key)

		_.extend opt, {
			form: opts
		} if opts?

		request.post opt, @_responseHandler callback

	# Returns an eventemitter that watches a key, emits 'change' on value change
	# or 'reconnect' when trying to recover from errors.
	watcher: (key, index = null) =>
		return new Watcher this, key, index

	# Get the etcd cluster machines
	machines: (callback) ->
		opt = @_prepareOpts "keys/_etcd/machines"
		request.get opt, @_responseHandler callback

	# Get the current cluster leader
	leader: (callback) ->
		opt = @_prepareOpts "leader"
		request.get opt, @_responseHandler callback

	# Get statistics about the leader
	leaderStats: (callback) ->
		opt = @_prepareOpts "stats/leader"
		request.get opt, @_responseHandler callback

	# Get statistics about the currently connected entity
	selfStats: (callback) ->
		opt = @_prepareOpts "stats/self"
		request.get opt, @_responseHandler callback

	# Get version of etcd
	version: (callback) ->
		opt = @_prepareOpts "", ""
		request.get opt, @_responseHandler callback

	# Strip the prefix slash if set
	_stripSlashPrefix: (key) ->
		key.replace /^\//, ''

	# Prepare request options
	_prepareOpts: (path, apiVersion = "/v1") ->
		protocol = "http"

		# Set up HttpsAgent if sslopts {ca, key, cert} are given
		if @sslopts?
			protocol = "https"
			httpsagent = new HttpsAgent
			_.extend httpsagent.options, @sslopts

		opt = {
			url: "#{protocol}://#{@host}:#{@port}#{apiVersion}/#{path}"
			json: true
			agent: httpsagent if httpsagent?
		}

	# Response handler for request
	_responseHandler: (callback) ->
		(err, resp, body) ->
			if body? and body.errorCode?
				callback body, ""
			else
				callback err, body

	# This is a workaround for issue #556 in the request library
	# 307 redirects are changed from POST to GET
	# https://github.com/mikeal/request/pull/556
	_postRedirectHandler: (opt, callback) ->
		request.post opt, (err, resp, body) =>
			# Follow if we get a 307 redirect to leader
			if resp and resp.statusCode is 307 and resp.headers.location?
				opt.url = resp.headers.location
				@_postRedirectHandler opt, callback
			else
				callback err, resp, body


exports = module.exports = Etcd
