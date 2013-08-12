require 'should'
nock = require 'nock'
etcd = new (require '../src/index.coffee')

# Tests for utility functions

describe 'Utility', () ->

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
			getNock().get('/leader').reply(200, '{"value":"value"}')
			etcd.leader checkVal done


