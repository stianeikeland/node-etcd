request = require 'request'
_       = require 'underscore'

class Etcd

	# Cunstructor, set etcd host and port
	constructor: (@host = '127.0.0.1', @port = '4001') ->

	# Get value for given key
	get: (key, callback) ->
		opt = @_prepareOpts "keys" + @_fixSlashPrefix(key)
		request opt, @_reponseHandler callback

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
		opt = @_prepareOpts "keys" + @_fixSlashPrefix(key)

		_.extend opt, {
			form: { value: value }
		}

		if extraopts?
			_.extend opt.form, extraopts

		request.post opt, @_reponseHandler callback

	# Delete given key
	del: (key, callback) ->
		opt = @_prepareOpts "keys" + @_fixSlashPrefix(key)
		request.del opt, @_reponseHandler callback

	_fixSlashPrefix: (key) ->
		key.replace("^/", "")

	_prepareOpts: (url) ->
		opt = {
			url: "http://#{@host}:#{@port}/v1/#{url}"
			json: true
		}

	_reponseHandler: (callback) ->
		(err, resp, body) ->
			if body.errorCode?
				callback body, ""
			else
				callback err, body


exports = module.exports = Etcd
