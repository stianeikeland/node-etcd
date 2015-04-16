should = require 'should'
nock = require 'nock'
Etcd = require '../src/index.coffee'

# Set env var to skip timeouts
process.env.RUNNING_UNIT_TESTS = true

# Helpers

getNock = (host = 'http://127.0.0.1:4001') ->
  nock host

# Tests for utility functions

describe 'Utility', ->

  etcd = new Etcd

  describe '#_stripSlashPrefix()', ->
    it 'should strip prefix-/ from key', ->
      etcd._stripSlashPrefix("/key/").should.equal("key/")
      etcd._stripSlashPrefix("key/").should.equal("key/")

  describe '#_prepareOpts()', ->
    it 'should return default request options', ->
      etcd._prepareOpts('keypath/key').should.containEql {
        json: true
        path: '/v2/keypath/key'
      }

describe 'Basic functions', ->

  etcd = new Etcd

  checkVal = (done) ->
    (err, val) ->
      val.should.containEql { value: "value" }
      done err, val

  describe '#get()', ->
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

    it 'should callback with error on error', (done) ->
      getNock()
        .get('/v2/keys/key')
        .reply(404, {"errorCode": 100, "message": "Key not found"})
      etcd.get 'key', (err, val) ->
        err.should.be.instanceOf Error
        err.error.errorCode.should.equal 100
        err.message.should.equal "Key not found"
        done()

  describe '#getSync()', ->
    it 'should synchronously return entry from etcd', (done) ->
      getNock()
        .get('/v2/keys/key')
        .reply(200, '{"action":"GET","key":"/key","value":"value","index":1}')
      val = etcd.getSync 'key'
      doneCheck = checkVal done
      doneCheck val.err, val.body

    it 'should synchronously return with error on error', (done) ->
      getNock()
        .get('/v2/keys/key')
        .reply(404, {"errorCode": 100, "message": "Key not found"})
      val = etcd.getSync 'key'
      val.err.should.be.instanceOf Error
      val.err.error.errorCode.should.equal 100
      val.err.message.should.equal "Key not found"
      done()


  describe '#set()', ->
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

  describe '#setSync()', ->
    it 'should synchronously put to etcd', (done) ->
      getNock()
        .put('/v2/keys/key', { value: "value" })
        .reply(200, '{"action":"SET","key":"/key","prevValue":"value","value":"value","index":1}')
      val = etcd.setSync 'key', 'value'
      doneCheck = checkVal done
      doneCheck val.err, val.body

  describe '#create()', ->
    it 'should post value to dir', (done) ->
      getNock()
        .post('/v2/keys/dir', { value: "value" })
        .reply(200, '{"action":"create", "node":{"key":"/dir/2"}}')

      etcd.create 'dir', 'value', (err, val) ->
        val.should.containEql { action: "create" }
        done err, val

  describe '#post()', ->
    it 'should post value to key', (done) ->
      getNock().post('/v2/keys/key', { value: "value" }).reply(200)
      etcd.post 'key', 'value', done


  describe '#compareAndSwap()', ->
    it 'should set using prevValue', (done) ->
      getNock()
        .put('/v2/keys/key?prevValue=oldvalue', { value: "value"})
        .reply(200, '{"action":"SET","key":"/key","prevValue":"oldvalue","value":"value","index":1}')
      etcd.compareAndSwap 'key', 'value', 'oldvalue', checkVal done

    it 'has alias testAndSet', ->
      etcd.testAndSet.should.equal etcd.testAndSet

  describe '#compareAndDelete', ->
    it 'should delete using prevValue', (done) ->
      getNock().delete('/v2/keys/key?prevValue=oldvalue').reply(200)
      etcd.compareAndDelete 'key', 'oldvalue', done

    it 'has alias testAndDelete', ->
      etcd.compareAndDelete.should.equal etcd.testAndDelete

  describe '#mkdir()', ->
    it 'should create directory', (done) ->
      getNock()
        .put('/v2/keys/key?dir=true')
        .reply(200, '{"action":"create","node":{"key":"/key","dir":true,"modifiedIndex":1,"createdIndex":1}}')
      etcd.mkdir 'key', (err, val) ->
        val.should.containEql {action: "create"}
        val.node.should.containEql {key: "/key"}
        val.node.should.containEql {dir: true}
        done()

  describe '#mkdirSync()', ->
    it 'should synchronously create directory', (done) ->
      getNock()
        .put('/v2/keys/key?dir=true')
        .reply(200, '{"action":"create","node":{"key":"/key","dir":true,"modifiedIndex":1,"createdIndex":1}}')
      val = etcd.mkdirSync 'key'
      val.body.should.containEql {action: "create"}
      val.body.node.should.containEql {key: "/key"}
      val.body.node.should.containEql {dir: true}
      done()

  describe '#rmdir()', ->
    it 'should remove directory', (done) ->
      getNock().delete('/v2/keys/key?dir=true').reply(200)
      etcd.rmdir 'key', done

  describe '#rmdirSync()', ->
    it 'should synchronously remove directory', (done) ->
      getNock().delete('/v2/keys/key?dir=true')
        .reply(200, '{"action":"delete","node":{"key":"/key","dir":true,"modifiedIndex":1,"createdIndex":3}}')
      val = etcd.rmdirSync 'key'
      val.body.should.containEql {action: "delete"}
      val.body.node.should.containEql {dir: true}
      done()

  describe '#del()', ->
    it 'should delete a given key in etcd', (done) ->
      getNock().delete('/v2/keys/key').reply(200)
      etcd.del 'key', done

  describe '#delSync()', ->
    it 'should synchronously delete a given key in etcd', (done) ->
      getNock().delete('/v2/keys/key2').reply(200, '{"action":"delete"}')
      val = etcd.delSync 'key2'
      val.body.should.containEql {action: "delete"}
      done()

  describe '#watch()', ->
    it 'should do a get with wait=true', (done) ->
      getNock()
        .get('/v2/keys/key?wait=true')
        .reply(200, '{"action":"set","key":"/key","value":"value","modifiedIndex":7}')
      etcd.watch 'key', checkVal done

  describe '#watchIndex()', ->
    it 'should do a get with wait=true and waitIndex=x', (done) ->
      getNock()
        .get('/v2/keys/key?waitIndex=1&wait=true')
        .reply(200, '{"action":"set","key":"/key","value":"value","modifiedIndex":7}')
      etcd.watchIndex 'key', 1, checkVal done

  describe '#raw()', ->
    it 'should use provided method', (done) ->
      getNock().patch('/key').reply(200, 'ok')
      etcd.raw 'PATCH', 'key', null, {}, done

    it 'should send provided value', (done) ->
      getNock().post('/key', { value: "value" }).reply(200, 'ok')
      etcd.raw 'POST', 'key', "value", {}, done

    it 'should call cb on value from etcd', (done) ->
      getNock().get('/key').reply(200, 'value')
      etcd.raw 'GET', 'key', null, {}, (err, val) ->
        val.should.equal 'value'
        done err, val

  describe '#machines()', ->
    it 'should ask etcd for connected machines', (done) ->
      getNock().get('/v2/keys/_etcd/machines').reply(200, '{"value":"value"}')
      etcd.machines checkVal done

  describe '#leader()', ->
    it 'should ask etcd for leader', (done) ->
      getNock().get('/v2/leader').reply(200, '{"value":"value"}')
      etcd.leader checkVal done

  describe '#leaderStats()', ->
    it 'should ask etcd for statistics for leader', (done) ->
      getNock().get('/v2/stats/leader').reply(200, '{"value":"value"}')
      etcd.leaderStats checkVal done

  describe '#selfStats()', ->
    it 'should ask etcd for statistics for connected server', (done) ->
      getNock().get('/v2/stats/self').reply(200, '{"value":"value"}')
      etcd.selfStats checkVal done

  describe '#version()', ->
    it 'should ask etcd for version', (done) ->
      getNock().get('/version').reply(200, 'etcd v0.1.0-8-gaad1626')
      etcd.version (err, val) ->
        val.should.equal 'etcd v0.1.0-8-gaad1626'
        done err, val


describe 'SSL support', ->

  it 'should use https url if sslopts is given', ->
    etcdssl = new Etcd 'localhost', '4001', {}
    opt = etcdssl._prepareOpts 'path'
    opt.serverprotocol.should.equal "https"

  it 'should set ca if ca is given', ->
    etcdsslca = new Etcd 'localhost', '4001', {ca: ['ca']}
    opt = etcdsslca._prepareOpts 'path'
    should.exist opt.agentOptions
    should.exist opt.agentOptions.ca
    opt.agentOptions.ca.should.eql ['ca']

  it 'should connect to https if sslopts is given', (done) ->
    getNock('https://localhost:4001')
      .get('/v2/keys/key')
      .reply(200, '{"action":"GET","key":"/key","value":"value","index":1}')

    etcdssl = new Etcd ['localhost:4001'], {ca: ['ca']}
    etcdssl.get 'key', done


describe 'Cancellation Token', ->

  beforeEach () ->
    nock.cleanAll()

  it 'should return token on request', ->
    getNock().get('/version').reply(200, 'etcd v0.1.0-8-gaad1626')
    etcd = new Etcd
    token = etcd.version()
    token.abort.should.be.a.function
    token.isAborted().should.be.false

  it 'should stop execution on abort', (done) ->
    http = getNock()
      .get('/v2/keys/key')
      .reply(200, '{"action":"GET","key":"/key","value":"value","index":1}')
    etcd = new Etcd '127.0.0.1', 4001

    token = etcd.version () -> throw new Error "Version call should have been aborted"
    token.abort()

    etcd.get 'key', () ->
      http.isDone().should.be.true
      done()


describe 'Multiserver/Cluster support', ->

  beforeEach () ->
    nock.cleanAll()

  it 'should accept list of servers in constructor', ->
    etcd = new Etcd ['localhost:4001', 'localhost:4002']
    etcd.getHosts().should.eql ['localhost:4001', 'localhost:4002']


  it 'should accept host and port in constructor', ->
    etcd = new Etcd 'localhost', 4001
    etcd.getHosts().should.eql ['localhost:4001']


  it 'should try next server in list on http error', (done) ->
    path = '/v2/keys/foo'
    response = '{"action":"GET","key":"/key","value":"value","index":1}'

    handler = (uri) ->
      nock.cleanAll()
      getNock('http://s1').get(path).reply(200, response)
      getNock('http://s2').get(path).reply(200, response)
      return {}

    getNock('http://s1').get(path).reply(500, handler)
    getNock('http://s2').get(path).reply(500, handler)

    etcd = new Etcd ['s1', 's2']
    etcd.get 'foo', (err, res) ->
      res.value.should.eql 'value'
      done()


  it 'should callback error if all servers failed', (done) ->
    path = '/v2/keys/foo'
    getNock('http://s1').get(path).reply(500, {})
    getNock('http://s2').get(path).reply(500, {})

    etcd = new Etcd ['s1', 's2']
    etcd.get 'foo', (err, res) ->
      err.should.be.an.instanceOf Error
      err.errors.should.have.lengthOf 2
      done()


  describe 'when cluster is doing leader elect', () ->

    it 'should retry on connection refused', (done) ->
      etcd = new Etcd ("localhost:#{p}" for p in [47187, 47188, 47189])
      token = etcd.set 'a', 'b', (err) ->
        err.errors.length.should.be.exactly 12
        token.errors.length.should.be.exactly 12
        token.retries.should.be.exactly 3
        done()

    it 'should allow maxRetries to control number of retries', (done) ->
      etcd = new Etcd ("localhost:#{p}" for p in [47187, 47188, 47189])
      token = etcd.set 'a', 'b', { maxRetries: 1 }, (err) ->
        err.errors.length.should.be.exactly 6
        token.retries.should.be.exactly 1
        done()
