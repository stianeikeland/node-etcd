request = require 'request'
_       = require 'underscore'

# Default options for request library
defaultOptions =
  pool:
    maxSockets: 100
  followAllRedirects: true


class Client

  constructor: (@hosts, @sslopts) ->

  execute: (method, options, callback) =>
    opt = _.defaults (_.clone options), defaultOptions, { method: method }
    @_executeHelper @hosts, opt, callback

  put: (options, callback) => @execute "PUT", options, callback
  get: (options, callback) => @execute "GET", options, callback
  post: (options, callback) => @execute "POST", options, callback
  patch: (options, callback) => @execute "PATCH", options, callback
  delete: (options, callback) => @execute "DELETE", options, callback

  # Multiserver (cluster) executer
  _executeHelper: (servers, options, callback) =>
    host = _.first(servers)
    options.url ?= "#{options.protocol}://#{host}#{options.path}"

    request options, (err, resp, body) =>
      @_handleResponse err, resp, body, callback


  _handleResponse: (err, resp, body, callback) ->
    return if not callback?
    if body?.errorCode? # http ok, but etcd gave us an error
      error = new Error body?.message || 'Etcd error'
      error.errorCode = body.errorCode
      error.error = body
      callback error, "", (resp?.headers or {})
    else if err?
      error = new Error 'HTTP error'
      error.error = err
      callback error, null, (resp?.headers or {})
    else
      callback null, body, (resp?.headers or {})


exports = module.exports = Client
