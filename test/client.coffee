should = require 'should'
nock = require 'nock'
Client = require '../src/client.coffee'

describe 'Client', () ->

	client = new Client

	describe '#_handleResponse()', () ->

		it 'fails on http error', () ->
			client._handleResponse 'error', '', '', (err) ->
				err.should.equal 'error'

		it 'fails on etcd error', () ->
			client._handleResponse null, "resp", {errorCode: 100}, (err) ->
				err.errorCode.should.equal 100

		it 'succeeds on no errors', () ->
			client._handleResponse null, "resp", "data", (_, val) ->
				val.should.equal "data"

		it 'passthrough any headers set in response', () ->
			client._handleResponse null, {headers: {a: "b"}}, "data", (e, v, headers) ->
				headers.a.should.equal "b"

		it 'sets empty object as header if none received', () ->
			client._handleResponse null, null, "data", (e, v, headers) ->
				headers.should.be.an.Object
				Object.keys(headers).should.be.empty
