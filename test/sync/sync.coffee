should = require 'should'
Etcd = require '../../src/index.coffee'

# Set env var to skip timeouts
process.env.RUNNING_UNIT_TESTS = true

describe 'Basic synchronous functions (requires local running etcd server on 4001)', ->

  etcd = new Etcd

  checkVal = (done) ->
    (err, val) ->
      val.should.include { value: "value" }
      done err, val

  describe '#mkdirSync()', ->
    it 'should synchronously create directory', ->
      val = etcd.mkdirSync 'key'
      val.body.should.include {action: "set"}
      val.body.node.should.include {key: "/key"}
      val.body.node.should.include {dir: true}

  describe '#setSync()', ->
    it 'should synchronously put to etcd', ->
      val = etcd.setSync 'key/value', 'test123'
      val.body.should.include {action: "set"}
      val.body.node.should.include {value: "test123"}

  describe '#getSync()', ->
    it 'should synchronously return entry from etcd', ->
      val = etcd.getSync 'key/value'
      val.body.should.include {action: "get"}
      val.body.node.should.include {key: "/key/value"}
      val.body.node.should.include {value: "test123"}

    it 'should return with error on error', ->
      val = etcd.getSync 'key/boguskey'
      val.err.should.be.instanceOf Error
      val.err.error.errorCode.should.equal 100
      val.err.message.should.equal "Key not found"

  describe '#delSync()', ->
    it 'should synchronously delete a given key in etcd', ->
      val = etcd.delSync 'key/value'
      val.body.should.include {action: "delete"}
      val.body.prevNode.should.include {value: "test123"}

  describe '#rmdirSync()', ->
    it 'should synchronously remove directory', ->
      val = etcd.rmdirSync 'key'
      val.body.should.include {action: "delete"}
