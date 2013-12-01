should = require 'should'
nock = require 'nock'
Etcd = require '../src/index.coffee'

# Tests for utility functions

describe 'Utility', () ->

	etcd = new Etcd

	describe '#_stripSlashPrefix()', () ->
		it 'should strip prefix-/ from key', () ->
			etcd._stripSlashPrefix("/key/").should.equal("key/")
			etcd._stripSlashPrefix("key/").should.equal("key/")

	describe '#_prepareOpts()', () ->
		it 'should return default request options', () ->
			etcd._prepareOpts('keypath/key').should.include {
				json: true
				url: 'http://127.0.0.1:4001/v2/keypath/key'
			}

	describe '#_responseHandler()', () ->

		it 'should handle responses', () ->
			handler = etcd._responseHandler (err, val) ->
				err.should.equal 'err'
				val.should.equal 'body'
			handler 'err', '', 'body'

		it 'should handle errors', () ->
			handler = etcd._responseHandler (err, val) ->
				err.should.include {errorCode: 1}
				val.should.equal ''
			handler 'err', '', {errorCode: 1}


# Tests for exposed api functions

describe 'Basic functions', () ->

	etcd = new Etcd

	getNock = () ->
		nock 'http://127.0.0.1:4001'

	checkVal = (done) ->
		(err, val) ->
			val.should.include { value: "value" }
			done err, val

	describe '#get()', () ->
		it 'should return entry from etcd', (done) ->
			getNock()
				.get('/v2/keys/key')
				.reply(200, '{"action":"GET","key":"/key","value":"value","index":1}')
			etcd.get 'key', checkVal done

		it 'should send options to etcd as request url', (done) ->
			getNock()
				.get('/v2/keys/key?recursive=true')
				.reply(200, '{"action":"GET","key":"/key","value":"value","index":1}')
			etcd.get 'key', { recursive: true }, checkVal done

	describe '#set()', () ->
		it 'should put to etcd', (done) ->
			getNock()
				.put('/v2/keys/key', { value: "value" })
				.reply(200, '{"action":"SET","key":"/key","prevValue":"value","value":"value","index":1}')
			etcd.set 'key', 'value', checkVal done

		it 'should send options to etcd as request url', (done) ->
			getNock()
				.put('/v2/keys/key?prevValue=oldvalue', { value: "value"})
				.reply(200, '{"action":"SET","key":"/key","prevValue":"oldvalue","value":"value","index":1}')
			etcd.set 'key', 'value', { prevValue: "oldvalue" }, checkVal done

		it 'should follow 307 redirects', (done) ->
			(nock 'http://127.0.0.1:4002')
				.put('/v2/keys/key', { value: "value" })
				.reply(200, '{"action":"SET","key":"/key","prevValue":"value","value":"value","index":1}')

			(nock 'http://127.0.0.1:4001')
				.put('/v2/keys/key', { value: "value" })
				.reply(307, "", { location: "http://127.0.0.1:4002/v2/keys/key" })

			etcd.set 'key', 'value', checkVal done


	describe '#del()', () ->
		it 'should delete a given key in etcd', (done) ->
			getNock().delete('/v2/keys/key').reply(200)
			etcd.del 'key', done

	describe '#watch()', () ->
		it 'should do a get with wait=true', (done) ->
			getNock()
				.get('/v2/keys/key?wait=true')
				.reply(200, '{"action":"set","key":"/key","value":"value","modifiedIndex":7}')
			etcd.watch 'key', checkVal done

	describe '#watchIndex()', () ->
		it 'should do a get with wait=true and waitIndex=x', (done) ->
			getNock()
				.get('/v2/keys/key?waitIndex=1&wait=true')
				.reply(200, '{"action":"set","key":"/key","value":"value","modifiedIndex":7}')
			etcd.watchIndex 'key', 1, checkVal done

	describe '#machines()', () ->
		it 'should ask etcd for connected machines', (done) ->
			getNock().get('/v2/keys/_etcd/machines').reply(200, '{"value":"value"}')
			etcd.machines checkVal done

	describe '#leader()', () ->
		it 'should ask etcd for leader', (done) ->
			getNock().get('/v2/leader').reply(200, '{"value":"value"}')
			etcd.leader checkVal done

	describe '#leaderStats()', () ->
		it 'should ask etcd for statistics for leader', (done) ->
			getNock().get('/v2/stats/leader').reply(200, '{"value":"value"}')
			etcd.leaderStats checkVal done

	describe '#selfStats()', () ->
		it 'should ask etcd for statistics for connected server', (done) ->
			getNock().get('/v2/stats/self').reply(200, '{"value":"value"}')
			etcd.selfStats checkVal done

	describe '#version()', () ->
		it 'should ask etcd for version', (done) ->
			getNock().get('/version').reply(200, 'etcd v0.1.0-8-gaad1626')
			etcd.version (err, val) ->
				val.should.equal 'etcd v0.1.0-8-gaad1626'
				done err, val

describe 'SSL support', () ->

	it 'should use https url if sslopts is given', () ->
		etcdssl = new Etcd 'localhost', '4001', {}
		opt = etcdssl._prepareOpts 'path'
		opt.url.should.match(/^https:.+$/)

	it 'should create https.agent and set ca if ca is given', () ->
		etcdsslca = new Etcd 'localhost', '4001', {ca: ['ca']}
		opt = etcdsslca._prepareOpts 'path'
		should.exist opt.agent
		should.exist opt.agent.options.ca
		opt.agent.options.ca.should.eql ['ca']

