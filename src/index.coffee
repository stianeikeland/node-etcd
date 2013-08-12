request = require 'request'
_       = require 'underscore'

class EtcdClient

	# etcd host and port
	constructor: (@host = '127.0.0.1', @port = '4001') ->

	prepareOpts: (url) ->
		opt = {
			url: "http://#{@host}:#{@port}/v1/#{url}"
			json: true
		}

	reponseHandler: (callback) ->
		return (err, resp, body) ->
			if body.errorCode?
				callback body, ""
			else
				callback err, body

	# Get key
	get: (key, callback) ->
		opt = @prepareOpts "keys" + key
		request opt, @reponseHandler callback

	# Set key to value
	set: (key, value, callback) ->
		@setWithOpts key, value, {}, callback

    # Set key to value with time to live
	setTTL: (key, value, ttl, callback) ->
		@setWithOpts key, value, {ttl: ttl}, callback

    # Atomic test and set value
	setTest: (key, value, prevValue, callback) ->
		@setWithOpts key, value, {prevValue: prevValue}, callback

    # Atomic test and set value with ttl
	setTestTTL: (key, value, prevValue, ttl, callback) ->
		@setWithOpts key, value, {prevValue: prevValue, ttl: ttl}, callback

    # Set key to value with exta options (ttl, prevValue, etc)
	setWithOpts: (key, value, extraopts, callback) ->
		opt = @prepareOpts "keys" + key

		_.extend opt, {
			form: { value: value }
		}

		if extraopts?
			_.extend opt.form, extraopts

		request.post opt, @reponseHandler callback

	# Delete given key
	del: (key, callback) ->
		opt = @prepareOpts "keys" + key
		request.del opt, @reponseHandler callback


exports = module.exports = EtcdClient
