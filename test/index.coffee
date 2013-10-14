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
				url: 'http://127.0.0.1:4001/v1/keypath/key'
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
				.get('/v1/keys/key')
				.reply(200, '{"action":"GET","key":"/key","value":"value","index":1}')
			etcd.get 'key', checkVal done

	describe '#set()', () ->
		it 'should post key=value to etcd', (done) ->
			getNock()
				.post('/v1/keys/key', { value: "value" })
				.reply(200, '{"action":"SET","key":"/key","prevValue":"value","value":"value","index":1}')
			etcd.set 'key', 'value', checkVal done

		it 'should follow 307 redirects', (done) ->
			(nock 'http://127.0.0.1:4002')
				.post('/v1/keys/key', { value: "value" })
				.reply(200, '{"action":"SET","key":"/key","prevValue":"value","value":"value","index":1}')

			(nock 'http://127.0.0.1:4001')
				.post('/v1/keys/key', { value: "value" })
				.reply(307, "", { location: "http://127.0.0.1:4002/v1/keys/key" })

			etcd.set 'key', 'value', checkVal done

	describe '#setTest()', () ->
		it 'should set key=value with prevValue as formdata', (done) ->
			getNock()
				.post('/v1/keys/key', { value: "new", prevValue: "old" })
				.reply(200, '{"action":"SET","key":"/key","prevValue":"prev","value":"value","index":1}')
			etcd.setTest 'key', 'new', 'old', checkVal done

	describe '#del()', () ->
		it 'should delete a given key in etcd', (done) ->
			getNock().delete('/v1/keys/key').reply(200)
			etcd.del 'key', done

	describe '#watch()', () ->
		it 'should ask etcd to watch a given key', (done) ->
			getNock().get('/v1/watch/key').reply(200, {"action":"SET","key":"/key","value":"value","newKey":true,"index":2})
			etcd.watch 'key', checkVal done

	describe '#machines()', () ->
		it 'should ask etcd for connected machines', (done) ->
			getNock().get('/v1/keys/_etcd/machines').reply(200, '{"value":"value"}')
			etcd.machines checkVal done

	describe '#leader()', () ->
		it 'should ask etcd for leader', (done) ->
			getNock().get('/v1/leader').reply(200, '{"value":"value"}')
			etcd.leader checkVal done

	describe '#leaderStats()', () ->
		it 'should ask etcd for statistics for leader', (done) ->
			getNock().get('/v1/stats/leader').reply(200, '{"value":"value"}')
			etcd.leaderStats checkVal done

	describe '#selfStats()', () ->
		it 'should ask etcd for statistics for connected server', (done) ->
			getNock().get('/v1/stats/self').reply(200, '{"value":"value"}')
			etcd.selfStats checkVal done

	describe '#version()', () ->
		it 'should ask etcd for version', (done) ->
			getNock().get('/').reply(200, 'etcd v0.1.0-8-gaad1626')
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

