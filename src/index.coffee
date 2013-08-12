request = require 'request'
_       = require 'underscore'

class Etcd

	# Cunstructor, set etcd host and port
	constructor: (@host = '127.0.0.1', @port = '4001') ->

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

		request.post opt, @_responseHandler callback

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


	# Get the etcd cluster machines
	machines: (callback) ->
		opt = @_prepareOpts "keys/_etcd/machines"
		request.get opt, @_responseHandler callback

	# Get the current cluster leader
	leader: (callback) ->
		opt = @_prepareOpts "leader", ""
		request.get opt, @_responseHandler callback

	# Strip the prefix slash if set
	_stripSlashPrefix: (key) ->
		key.replace /^\//, ''

	_prepareOpts: (url, apiVersion = "/v1") ->
		opt = {
			url: "http://#{@host}:#{@port}#{apiVersion}/#{url}"
			json: true
		}

	_responseHandler: (callback) ->
		(err, resp, body) ->
			if body? and body.errorCode?
				callback body, ""
			else
				callback err, body


exports = module.exports = Etcd
