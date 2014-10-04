request = require 'request'
_       = require 'underscore'

class Client

  constructor: (@hosts, @sslopts) ->


  execute: (method, options, callback) =>
    host = @hosts[0]

    opt = _.clone options
    opt.method = method
    opt.url ?= "#{opt.protocol}://#{host}#{opt.path}"
    opt.pool = maxSockets: 100

    request opt, (err, resp, body) =>
      if @_wasRedirected resp
        @_handleRedirect method, resp.headers.location, opt, callback
      else
        @_handleResponse err, resp, body, callback


  put: (options, callback) => @execute "PUT", options, callback
  get: (options, callback) => @execute "GET", options, callback
  post: (options, callback) => @execute "POST", options, callback
  patch: (options, callback) => @execute "PATCH", options, callback
  delete: (options, callback) => @execute "DELETE", options, callback


  # This is a workaround for issue #556 in the request library
  # 307 redirects are changed from POST/PUT/DEL to GET
  # https://github.com/mikeal/request/pull/556
  _wasRedirected: (resp) ->
    resp?.statusCode? and resp.statusCode is 307 and resp?.headers?.location?


  _handleRedirect: (method, redirectURL, options, callback) =>
    opt = _.clone options
    opt.url = redirectURL
    @execute method, opt, callback


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
