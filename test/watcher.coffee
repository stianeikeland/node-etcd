require 'should'
Watcher = require '../src/watcher.coffee'

class FakeEtcd
	constructor: ->
		@stopped = false
		@cb = ->

	abort: -> {abort: => @stopped = true}

	watch: (key, options, cb) ->
		key.should.equal 'key'
		@cb = cb
		return @abort()

	watchIndex: (key, index, options, cb) ->
		key.should.equal 'key'
		@cb = cb
		return @abort()

	change: (err, val) ->
		@cb err, val


describe 'Watcher', ->
	it 'should emit change on watch change', (done) ->
		etcd = new FakeEtcd
		w = new Watcher etcd, 'key'

		w.on 'change', (val) ->
			val.should.include { node: { modifiedIndex: 0 } }
			done()

		etcd.change null, { node: { modifiedIndex: 0 } }

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
		w.on 'error', -> done()

		etcd.change null, 'invalid content', {}

	it 'should emit error object on error', (done) ->
		etcd = new FakeEtcd
		w = new Watcher etcd, 'key'
		w.on 'error', (err) ->
			err.should.be.an.instanceOf Error
			done()

		etcd.change null, 'invalid content', {}

	it 'should use provided options', (done) ->
		etcd = new FakeEtcd

		etcd.watch = (key, opt, cb) ->
			opt.should.include { recursive: true }
			done()

		w = new Watcher etcd, 'key', null, { recursive: true }

	it 'should emit action on event', (done) ->
		etcd = new FakeEtcd
		w = new Watcher etcd, 'key'
		w.on 'set', (res) -> done()

		etcd.change null, { action: 'set', node: { key: '/key', value: 'value', modifiedIndex: 1, createdIndex: 1 } }

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

		etcd.change null, { node: { modifiedIndex: i } }

	it 'should abort request when stop is called', ->
		etcd = new FakeEtcd
		w = new Watcher etcd, 'key'

		w.stop()
		etcd.stopped.should.be.true

	it 'should emit stop when stopped', (done) ->
		etcd = new FakeEtcd
		w = new Watcher etcd, 'key'

		w.on 'stop', -> done()
		w.stop()


