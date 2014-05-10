_       = require 'underscore'
Watcher = require './watcher'
Client = require './client'
HttpsAgent = (require 'https').Agent

# Etcd client for etcd protocol version 2
class Etcd

  # Constructor, set etcd host and port.
  # For https: provide {ca, crt, key} as sslopts.
  constructor: (@host = '127.0.0.1', @port = '4001', @sslopts = null, @client = null) ->
    @client ?= new Client(@sslopts)

  # Set key to value
  # Usage:
  #   .set("key", "value", callback)
  #   .set("key", "value", {prevValue: "oldvalue"}, callback)
  set: (key, value, options, callback) ->
    [options, callback] = @_argParser options, callback
    opt = @_prepareOpts ("keys/" + @_stripSlashPrefix key), "/v2", value, options
    @client.put opt, callback

  # Get value of key
  # Usage:
  #   .get("key", callback)
  #   .get("key", {recursive: true}, callback)
  get: (key, options, callback) ->
    [options, callback] = @_argParser options, callback
    opt = @_prepareOpts ("keys/" + @_stripSlashPrefix key), "/v2", null, options
    @client.get opt, callback

  # Create a key (atomic in order)
  # Usage:
  #   .create("path", "value", callback)
  #   .create("path", "value", options, callback)
  create: (dir, value, options, callback) ->
    [options, callback] = @_argParser options, callback
    opt = @_prepareOpts ("keys/" + @_stripSlashPrefix dir), "/v2", value, options
    @client.post opt, callback

  post: @::create

  # Delete a key
  # Usage:
  #   .del("key", callback)
  #   .del("key", {recursive: true}, callback)
  #   .delete("key", callback)
  del: (key, options, callback) ->
    [options, callback] = @_argParser options, callback
    opt = @_prepareOpts ("keys/" + @_stripSlashPrefix key), "/v2", null, options
    @client.delete opt, callback

  delete: @::del

  # Make a directory
  # Usage:
  #   .mkdir("dir", callback)
  #   .mkdir("dir", options, callback)
  mkdir: (dir, options, callback) ->
    [options, callback] = @_argParser options, callback
    options.dir = true
    @set dir, null, options, callback

  # Remove a directory
  # Usage:
  #   .rmdir("dir", callback)
  #   .rmdir("dir", {recursive: true}, callback)
  rmdir: (dir, options, callback) ->
    [options, callback] = @_argParser options, callback
    options.dir = true
    @del dir, options, callback

  # Compare and swap value if unchanged
  # Usage:
  #   .compareAndSwap("key", "newValue", "oldValue", callback)
  #   .compareAndSwap("key", "newValue", "oldValue", options, callback)
  #   .testAndSet("key", "newValue", "oldValue", options, callback)
  compareAndSwap: (key, value, oldvalue, options, callback) ->
    [options, callback] = @_argParser options, callback
    options ?= {}
    options.prevValue = oldvalue

    @set key, value, options, callback

  testAndSet: @::compareAndSwap

  # Compare and delete if value is unchanged
  # Usage:
  #   .compareAndDelete("key", "oldValue", options, callback)
  compareAndDelete: (key, oldvalue, options, callback) ->
    [options, callback] = @_argParser options, callback
    options ?= {}
    options.prevValue = oldvalue

    @del key, options, callback

  testAndDelete: @::compareAndDelete

  # Execute a raw etcd query
  # Where method is one of: PUT, GET, POST, PATCH, DELETE
  #
  # Usage:
  #   .raw("METHOD", "path", "value", options, callback)
  #   .raw("GET", "v2/stats/leader", null, {}, callback)
  #   .raw("PUT", "v2/keys/key", "value", {}, callback)
  raw: (method, key, value, options, callback) ->
    [options, callback] = @_argParser options, callback
    opt = @_prepareOpts key, "", value, options
    @client.execute method, opt, callback

  # Watch for value changes on a key
  watch: (key, options, callback) ->
    [options, callback] = @_argParser options, callback
    options ?= {}
    options.wait = true

    @get key, options, callback

  # Watch for value changes on a key since a specific index
  watchIndex: (key, index, options, callback) ->
    [options, callback] = @_argParser options, callback
    options ?= {}
    options.waitIndex = index

    @watch key, options, callback

  # Returns an eventemitter that watches a key, emits 'change' on value change
  # or 'reconnect' when trying to recover from errors.
  watcher: (key, index = null, options = {}) =>
    return new Watcher this, key, index, options


  # Get the etcd cluster machines
  machines: (callback) ->
    opt = @_prepareOpts "keys/_etcd/machines"
    @client.get opt, callback

  # Get the current cluster leader
  leader: (callback) ->
    opt = @_prepareOpts "leader"
    @client.get opt, callback

  # Get statistics about the leader
  leaderStats: (callback) ->
    opt = @_prepareOpts "stats/leader"
    @client.get opt, callback

  # Get statistics about the currently connected entity
  selfStats: (callback) ->
    opt = @_prepareOpts "stats/self"
    @client.get opt, callback

  # Get version of etcd
  version: (callback) ->
    opt = @_prepareOpts "version", ""
    @client.get opt, callback


  # Strip the prefix slash if set
  _stripSlashPrefix: (key) ->
    key.replace /^\//, ''

  # Prepare request options
  _prepareOpts: (path, apiVersion = "/v2", value = null, queryString = null) ->
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
      qs: queryString if queryString?
      form: { value: value } if value?
    }

  # Swap callback and options if no options was given.
  _argParser: (options, callback) ->
    if typeof options is 'function'
      [{}, options]
    else
      [options, callback]

exports = module.exports = Etcd
