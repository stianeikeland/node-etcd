require 'should'
Watcher = require '../src/watcher.coffee'

class FakeEtcd
	constructor: () ->
		@cb = () ->

	watch: (key, cb) ->
		key.should.equal 'key'
		@cb = cb

	watchIndex: (key, index, cb) ->
		key.should.equal 'key'
		@cb = cb

	change: (err, val) ->
		@cb err, val


describe 'Watcher', () ->
	it 'should emit change on watch change', (done) ->
		etcd = new FakeEtcd
		w = new Watcher etcd, 'key'

		w.on 'change', (val) ->
			val.should.include { index: 0 }
			done()

		etcd.change null, { index: 0 }

	it 'should emit reconnect event on error', (done) ->
		etcd = new FakeEtcd
		w = new Watcher etcd, 'key'

		w.on 'reconnect', (err) ->
			err.should.include { error: "error" }
			done()

		etcd.change "error", null

	it 'should emit error if received content is invalid', (done) ->
		etcd = new FakeEtcd
		w = new Watcher etcd, 'key'
		w.on 'error', () -> done()

		etcd.change null, 'invalid content'

	it 'should reconnect (call watch again) on error', (done) ->
		etcd = new FakeEtcd
		w = new Watcher etcd, 'key'

		etcd.watch = (key, cb) ->
			w.retryAttempts.should.equal 1
			done()

		etcd.change "error", null

	it 'should call watch on next index after getting change', (done) ->
		etcd = new FakeEtcd
		w = new Watcher etcd, 'key'

		i = 5

		etcd.watchIndex = (key, index, cb) ->
			index.should.equal i + 1
			done()

		etcd.change null, { index: i }


