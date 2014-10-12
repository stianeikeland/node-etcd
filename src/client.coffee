request = require 'request'
_       = require 'underscore'

# Default options for request library
defaultOptions =
  pool:
    maxSockets: 100
  followAllRedirects: true

# CancellationToken to abort a request
class CancellationToken
  constructor: (@hosts) ->
    @aborted = false

  setRequest: (req) =>
    @req = req

  isAborted: () =>
    @aborted

  abort: () =>
    @aborted = true
    @req.abort() if @req?

  cancel: @::abort

# HTTP Client for connecting to etcd servers
class Client

  constructor: (@hosts, @sslopts) ->

  execute: (method, options, callback) =>
    opt = _.defaults (_.clone options), defaultOptions, { method: method }
    servers = _.shuffle @hosts
    token = new CancellationToken servers
    @_multiserverHelper servers, opt, token, errors = [], callback
    return token

  put: (options, callback) => @execute "PUT", options, callback
  get: (options, callback) => @execute "GET", options, callback
  post: (options, callback) => @execute "POST", options, callback
  patch: (options, callback) => @execute "PATCH", options, callback
  delete: (options, callback) => @execute "DELETE", options, callback

  # Multiserver (cluster) executer
  _multiserverHelper: (servers, options, token, errors, callback) =>
    host = _.first(servers)
    options.url = "#{options.serverprotocol}://#{host}#{options.path}"

    return if token.isAborted() # Aborted by user?

    if not host? # No servers left?
      error = new Error 'All servers returned error'
      error.errors = errors
      return callback error

    token.setRequest request options, (err, resp, body) =>
      if @_isHttpError err, resp
        errors.push { server: host, error: "TODO" }
        # Recurse:
        @_multiserverHelper _.rest(servers), options, token, errors, callback
      else if not token.isAborted()
        @_handleResponse err, resp, body, callback

  _isHttpError: (err, resp) ->
    err or (resp?.statusCode? and resp.statusCode >= 500)


  _handleResponse: (err, resp, body, callback) ->
    return if not callback?
    if body?.errorCode? # http ok, but etcd gave us an error
      error = new Error body?.message || 'Etcd error'
      error.errorCode = body.errorCode
      error.error = body
      callback error, "", (resp?.headers or {})
    # else if err? or @_httpError resp
    #   error = new Error 'HTTP error'
    #   error.error = err
      # callback error, null, (resp?.headers or {})
    else
      callback null, body, (resp?.headers or {})


exports = module.exports = Client
