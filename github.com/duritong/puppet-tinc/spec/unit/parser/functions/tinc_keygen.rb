#! /usr/bin/env ruby


require File.dirname(__FILE__) + '/../../../spec_helper'

require 'mocha'
require 'fileutils'

describe "the tinc_keygen function" do

  before :each do
    @scope = Puppet::Parser::Scope.new
  end

  it "should exist" do
    Puppet::Parser::Functions.function("tinc_keygen").should == "function_tinc_keygen"
  end

  it "should raise a ParseError if no argument is passed" do
    lambda { @scope.function_tinc_keygen([]) }.should( raise_error(Puppet::ParseError))
  end

  it "should raise a ParseError if there is more than 2 arguments" do
    lambda { @scope.function_tinc_keygen(["foo", "bar", "foo"]) }.should( raise_error(Puppet::ParseError))
  end

  it "should raise a ParseError if the second argument is not fully qualified" do
    lambda { @scope.function_tinc_keygen(["foo","bar"]) }.should( raise_error(Puppet::ParseError))
  end

  it "should raise a ParseError if the private key path is a directory" do
    File.stubs(:directory?).with("/some_dir/rsa_key.priv").returns(true)
    lambda { @scope.function_tinc_keygen(['foo',"/some_dir"]) }.should( raise_error(Puppet::ParseError))
  end

  it "should raise a ParseError if the public key path is a directory" do
    File.stubs(:directory?).with("/some_dir/rsa_key.pub").returns(true)
    lambda { @scope.function_tinc_keygen(['foo',"/some_dir"]) }.should( raise_error(Puppet::ParseError))
  end

  describe "when executing properly" do
    before do
      File.stubs(:directory?).with('/tmp/a/b/rsa_key.priv').returns(false)
      File.stubs(:directory?).with('/tmp/a/b/rsa_key.pub').returns(false)
      File.stubs(:read).with('/tmp/a/b/rsa_key.priv').returns('privatekey')
      File.stubs(:read).with('/tmp/a/b/rsa_key.pub').returns('publickey')
    end

    it "should fail if the public but not the private key exists" do
      File.stubs(:exists?).with("/tmp/a/b/rsa_key.priv").returns(true)
      File.stubs(:exists?).with("/tmp/a/b/rsa_key.pub").returns(false)
      lambda { @scope.function_tinc_keygen(['foo',"/tmp/a/b"]) }.should( raise_error(Puppet::ParseError))
    end

    it "should fail if the private but not the public key exists" do
      File.stubs(:exists?).with("/tmp/a/b/rsa_key.priv").returns(true)
      File.stubs(:exists?).with("/tmp/a/b/rsa_key.pub").returns(false)
      lambda { @scope.function_tinc_keygen(['foo',"/tmp/a/b"]) }.should( raise_error(Puppet::ParseError))
    end


    it "should return an array of size 2 with the right content if the keyfiles exists" do
      File.stubs(:exists?).with("/tmp/a/b/rsa_key.priv").returns(true)
      File.stubs(:exists?).with("/tmp/a/b/rsa_key.pub").returns(true)
      File.stubs(:directory?).with('/tmp/a/b').returns(true)
      Puppet::Util.expects(:execute).never
      result = @scope.function_tinc_keygen(['foo','/tmp/a/b'])
      result.length.should == 2
      result[0].should == 'privatekey'
      result[1].should == 'publickey'
    end

    it "should create the directory path if it does not exist" do
      File.stubs(:exists?).with("/tmp/a/b/rsa_key.priv").returns(false)
      File.stubs(:exists?).with("/tmp/a/b/rsa_key.pub").returns(false)
      File.stubs(:directory?).with("/tmp/a/b").returns(false)
      FileUtils.expects(:mkdir_p).with("/tmp/a/b", :mode => 0700)
      Puppet::Util.expects(:execute).returns("foo\nbar\nGenerating 2048 bits keys\n++++\n---")
      result = @scope.function_tinc_keygen(['foo','/tmp/a/b'])
      result.length.should == 2
      result[0].should == 'privatekey'
      result[1].should == 'publickey'
    end

    it "should generate the key if the keyfiles do not exist" do
      File.stubs(:exists?).with("/tmp/a/b/rsa_key.priv").returns(false)
      File.stubs(:exists?).with("/tmp/a/b/rsa_key.pub").returns(false)
      File.stubs(:directory?).with("/tmp/a/b").returns(true)
      Puppet::Util.expects(:execute).with(['/usr/sbin/tincd','-c', '/tmp/a/b', '-n', 'foo', '-K']).returns("foo\nbar\nGenerating 2048 bits keys\n++++\n---")
      result = @scope.function_tinc_keygen(['foo','/tmp/a/b'])
      result.length.should == 2
      result[0].should == 'privatekey'
      result[1].should == 'publickey'
    end

    it "should fail if something goes wrong during generation" do
      File.stubs(:exists?).with("/tmp/a/b/rsa_key.priv").returns(false)
      File.stubs(:exists?).with("/tmp/a/b/rsa_key.pub").returns(false)
      File.stubs(:directory?).with("/tmp/a/b").returns(true)
      Puppet::Util.expects(:execute).with(['/usr/sbin/tincd','-c', '/tmp/a/b', '-n', 'foo', '-K']).returns("something is wrong")
      lambda { @scope.function_tinc_keygen(['foo',"/tmp/a/b"]) }.should( raise_error(Puppet::ParseError))
    end
  end
end
