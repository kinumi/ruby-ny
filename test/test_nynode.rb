#coding: utf-8

require File.dirname(__FILE__) + "/../lib/nynode.rb"
require "rubygems"
require "shoulda"

class TestNyNode < Test::Unit::TestCase
  #========================================================================================================================================
  context "ノード" do
    should "暗号化アドレスから作成できる" do
      node = NyNode.new(:enc_addr => "@b64ece6f6b7d6eb60bb43e1f3ffe77d59426b861")
      assert_equal(
        "@b64ece6f6b7d6eb60bb43e1f3ffe77d59426b861",
        node.enc_addr
        )
      assert_equal(
        "192.168.1.210",
        node.host
        )
      assert_equal(
        20100,
        node.port
        )
    end
    
    should "ホストとポートから作成できる" do
      node = NyNode.new(:host => "192.168.1.210", :port => 20100)
      assert_equal(
        "@b64ece6f6b7d6eb60bb43e1f3ffe77d59426b861",
        node.enc_addr
        )
      assert_equal(
        "192.168.1.210",
        node.host
        )
      assert_equal(
        20100,
        node.port
        )
    end
    
    should "パラメータを指定しなかったときは例外が発生する" do
      assert_raise(RuntimeError) do
        NyNode.new
      end
    end
    
    should "IPアドレスが不正の場合は例外が発生する" do
      assert_raise(RuntimeError) do
        node = NyNode.new(:host => "192.168.1.", :port => 20100)
      end
    end
  end
end
