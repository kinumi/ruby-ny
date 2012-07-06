#coding: utf-8

require File.dirname(__FILE__) + "/../lib/nycommands.rb"
require File.dirname(__FILE__) + "/lib/testcommands.rb"
require "rubygems"
require "test/unit"
require "shoulda"

class TestNyCommand < Test::Unit::TestCase
  #========================================================================================================================================
  context "数値のみコマンド" do
    setup do
      @cmdcls = T01
    end
    
    should "空のコマンドを作成できる" do
      cmd = @cmdcls.new
      assert_equal(
        7,
        cmd.size
        )
      assert_equal(
        "\x00\x00\x00\x00\x00\x00\x00".unpack("C*").pack("C*"),
        cmd.to_byte
        )
      assert_equal(
        "\x08\x00\x00\x00\xff\x00\x00\x00\x00\x00\x00\x00".unpack("C*").pack("C*"),
        cmd.to_packet
        )
    end
    
    should "コマンドを作成できる" do
      cmd = @cmdcls.new
      cmd.a = 1
      cmd.b = 2
      cmd.c = 3
      assert_equal(
        7,
        cmd.size
        )
      assert_equal(
        "\x01\x02\x00\x03\x00\x00\x00".unpack("C*").pack("C*"),
        cmd.to_byte
        )
      assert_equal(
        "\x08\x00\x00\x00\xff\x01\x02\x00\x03\x00\x00\x00".unpack("C*").pack("C*"),
        cmd.to_packet
        )
    end
    
    should "コマンドを解釈できる" do
      cmd = @cmdcls.new("\x01\x02\x00\x03\x00\x00\x00".unpack("C*").pack("C*"))
      assert_equal(
        7,
        cmd.size
        )
      assert_equal(
        "\x01\x02\x00\x03\x00\x00\x00".unpack("C*").pack("C*"),
        cmd.to_byte
        )
      assert_equal(
        "\x08\x00\x00\x00\xff\x01\x02\x00\x03\x00\x00\x00".unpack("C*").pack("C*"),
        cmd.to_packet
        )
    end
    
    should "小さいコマンドを解釈できる" do
      cmd = @cmdcls.new("\x01".unpack("C*").pack("C*"))
      assert_equal(
        7,
        cmd.size
        )
      assert_equal(
        "\x01\x00\x00\x00\x00\x00\x00".unpack("C*").pack("C*"),
        cmd.to_byte
        )
      assert_equal(
        "\x08\x00\x00\x00\xff\x01\x00\x00\x00\x00\x00\x00".unpack("C*").pack("C*"),
        cmd.to_packet
        )
    end
    
    should "空のコマンドを解釈できる" do
      cmd = @cmdcls.new("".unpack("C*").pack("C*"))
      assert_equal(
        7,
        cmd.size
        )
      assert_equal(
        "\x00\x00\x00\x00\x00\x00\x00".unpack("C*").pack("C*"),
        cmd.to_byte
        )
      assert_equal(
        "\x08\x00\x00\x00\xff\x00\x00\x00\x00\x00\x00\x00".unpack("C*").pack("C*"),
        cmd.to_packet
        )
    end
    
    should "大きいコマンドを解釈できる" do
      cmd = @cmdcls.new("\x01\x02\x00\x03\x00\x00\x00\x04".unpack("C*").pack("C*"))
      assert_equal(
        7,
        cmd.size
        )
      assert_equal(
        "\x01\x02\x00\x03\x00\x00\x00".unpack("C*").pack("C*"),
        cmd.to_byte
        )
      assert_equal(
        "\x08\x00\x00\x00\xff\x01\x02\x00\x03\x00\x00\x00".unpack("C*").pack("C*"),
        cmd.to_packet
        )
    end
  end
  
  
  #========================================================================================================================================
  context "固定長文字列入りコマンド" do
    setup do
      @cmdcls = T02
    end
    
    should "空のコマンドを作成できる" do
      cmd = @cmdcls.new
      assert_equal(
        6,
        cmd.size
        )
      assert_equal(
        "\x00\x00\x00\x00\x00\x00".unpack("C*").pack("C*"),
        cmd.to_byte
        )
      assert_equal(
        "\x07\x00\x00\x00\xfe\x00\x00\x00\x00\x00\x00".unpack("C*").pack("C*"),
        cmd.to_packet
        )
    end
    
    should "コマンドを作成できる" do
      cmd = @cmdcls.new
      cmd.a = 1
      cmd.b = "abcde"
      assert_equal(
        6,
        cmd.size
        )
      assert_equal(
        "\x01abcde".unpack("C*").pack("C*"),
        cmd.to_byte
        )
      assert_equal(
        "\x07\x00\x00\x00\xfe\x01abcde".unpack("C*").pack("C*"),
        cmd.to_packet
        )
    end
    
    should "指定サイズよりも大きい文字列を指定した時、コマンドを作成できる" do
      cmd = @cmdcls.new
      cmd.a = 1
      cmd.b = "abcdefg"
      assert_equal(
        6,
        cmd.size
        )
      assert_equal(
        "\x01abcde".unpack("C*").pack("C*"),
        cmd.to_byte
        )
      assert_equal(
        "\x07\x00\x00\x00\xfe\x01abcde".unpack("C*").pack("C*"),
        cmd.to_packet
        )
    end
    
    should "指定サイズに満たない文字列を指定した時、コマンドを作成できる" do
      cmd = @cmdcls.new
      cmd.a = 1
      cmd.b = "a"
      assert_equal(
        6,
        cmd.size
        )
      assert_equal(
        "\x01a\x00\x00\x00\x00".unpack("C*").pack("C*"),
        cmd.to_byte
        )
      assert_equal(
        "\x07\x00\x00\x00\xfe\x01a\x00\x00\x00\x00".unpack("C*").pack("C*"),
        cmd.to_packet
        )
    end
    
    should "コマンドを解釈できる" do
      cmd = @cmdcls.new("\x01abcde".unpack("C*").pack("C*"))
      assert_equal(
        6,
        cmd.size
        )
      assert_equal(
        "\x01abcde".unpack("C*").pack("C*"),
        cmd.to_byte
        )
      assert_equal(
        "\x07\x00\x00\x00\xfe\x01abcde".unpack("C*").pack("C*"),
        cmd.to_packet
        )
    end
    
    should "小さいコマンドを解釈できる" do
      cmd = @cmdcls.new("\x01a".unpack("C*").pack("C*"))
      assert_equal(
        6,
        cmd.size
        )
      assert_equal(
        "\x01a\x00\x00\x00\x00".unpack("C*").pack("C*"),
        cmd.to_byte
        )
      assert_equal(
        "\x07\x00\x00\x00\xfe\x01a\x00\x00\x00\x00".unpack("C*").pack("C*"),
        cmd.to_packet
        )
    end
    
    should "空のコマンドを解釈できる" do
      cmd = @cmdcls.new("".unpack("C*").pack("C*"))
      assert_equal(
        6,
        cmd.size
        )
      assert_equal(
        "\x00\x00\x00\x00\x00\x00".unpack("C*").pack("C*"),
        cmd.to_byte
        )
      assert_equal(
        "\x07\x00\x00\x00\xfe\x00\x00\x00\x00\x00\x00".unpack("C*").pack("C*"),
        cmd.to_packet
        )
    end
    
    should "大きいコマンドを解釈できる" do
      cmd = @cmdcls.new("\x01abcdefg".unpack("C*").pack("C*"))
      assert_equal(
        6,
        cmd.size
        )
      assert_equal(
        "\x01abcde".unpack("C*").pack("C*"),
        cmd.to_byte
        )
      assert_equal(
        "\x07\x00\x00\x00\xfe\x01abcde".unpack("C*").pack("C*"),
        cmd.to_packet
        )
    end
  end

  #========================================================================================================================================
  context "可変長文字列入りコマンド" do
    setup do
      @cmdcls = T03
    end
    
    should "空のコマンドを作成できる" do
      cmd = @cmdcls.new
      assert_equal(
        1,
        cmd.size
        )
      assert_equal(
        "\x00".unpack("C*").pack("C*"),
        cmd.to_byte
        )
      assert_equal(
        "\x02\x00\x00\x00\xfd\x00".unpack("C*").pack("C*"),
        cmd.to_packet
        )
    end
    
    should "コマンドを作成できる" do
      cmd = @cmdcls.new
      cmd.a = 1
      cmd.b = "a"
      assert_equal(
        2,
        cmd.size
        )
      assert_equal(
        "\x01a".unpack("C*").pack("C*"),
        cmd.to_byte
        )
      assert_equal(
        "\x03\x00\x00\x00\xfd\x01a".unpack("C*").pack("C*"),
        cmd.to_packet
        )
    end
    
    should "指定サイズよりも大きい文字列を指定した時、コマンドを作成できる" do
      cmd = @cmdcls.new
      cmd.a = 1
      cmd.b = "abcdefg"
      assert_equal(
        2,
        cmd.size
        )
      assert_equal(
        "\x01a".unpack("C*").pack("C*"),
        cmd.to_byte
        )
      assert_equal(
        "\x03\x00\x00\x00\xfd\x01a".unpack("C*").pack("C*"),
        cmd.to_packet
        )
    end
    
    should "指定サイズに満たない文字列を指定した時、コマンドを作成できる" do
      cmd = @cmdcls.new
      cmd.a = 2
      cmd.b = "a"
      assert_equal(
        3,
        cmd.size
        )
      assert_equal(
        "\x02a\x00".unpack("C*").pack("C*"),
        cmd.to_byte
        )
      assert_equal(
        "\x04\x00\x00\x00\xfd\x02a\x00".unpack("C*").pack("C*"),
        cmd.to_packet
        )
    end
    
    should "コマンドを解釈できる" do
      cmd = @cmdcls.new("\x01a".unpack("C*").pack("C*"))
      assert_equal(
        2,
        cmd.size
        )
      assert_equal(
        "\x01a".unpack("C*").pack("C*"),
        cmd.to_byte
        )
      assert_equal(
        "\x03\x00\x00\x00\xfd\x01a".unpack("C*").pack("C*"),
        cmd.to_packet
        )
    end
    
    should "小さいコマンドを解釈できる" do
      cmd = @cmdcls.new("\x02a".unpack("C*").pack("C*"))
      assert_equal(
        3,
        cmd.size
        )
      assert_equal(
        "\x02a\x00".unpack("C*").pack("C*"),
        cmd.to_byte
        )
      assert_equal(
        "\x04\x00\x00\x00\xfd\x02a\x00".unpack("C*").pack("C*"),
        cmd.to_packet
        )
    end
    
    should "空のコマンドを解釈できる" do
      cmd = @cmdcls.new("".unpack("C*").pack("C*"))
      assert_equal(
        1,
        cmd.size
        )
      assert_equal(
        "\x00".unpack("C*").pack("C*"),
        cmd.to_byte
        )
      assert_equal(
        "\x02\x00\x00\x00\xfd\x00".unpack("C*").pack("C*"),
        cmd.to_packet
        )
    end
    
    should "大きいコマンドを解釈できる" do
      cmd = @cmdcls.new("\x01abcdefg".unpack("C*").pack("C*"))
      assert_equal(
        2,
        cmd.size
        )
      assert_equal(
        "\x01a".unpack("C*").pack("C*"),
        cmd.to_byte
        )
      assert_equal(
        "\x03\x00\x00\x00\xfd\x01a".unpack("C*").pack("C*"),
        cmd.to_packet
        )
    end
  end

  #========================================================================================================================================
  context "IPアドレス入りコマンド" do
    setup do
      @cmdcls = T04
    end
    
    should "空のコマンドを作成できる" do
      cmd = @cmdcls.new
      assert_equal(
        4,
        cmd.size
        )
      assert_equal(
        "\x00\x00\x00\x00".unpack("C*").pack("C*"),
        cmd.to_byte
        )
      assert_equal(
        "\x05\x00\x00\x00\xfc\x00\x00\x00\x00".unpack("C*").pack("C*"),
        cmd.to_packet
        )
    end
    
    should "コマンドを作成できる" do
      cmd = @cmdcls.new
      cmd.ipaddr = "1.2.3.4"
      assert_equal(
        4,
        cmd.size
        )
      assert_equal(
        "\x01\x02\x03\x04".unpack("C*").pack("C*"),
        cmd.to_byte
        )
      assert_equal(
        "\x05\x00\x00\x00\xfc\x01\x02\x03\x04".unpack("C*").pack("C*"),
        cmd.to_packet
        )
    end
  end

  #========================================================================================================================================
  context "サブコマンド入りコマンド" do
    setup do
      @cmdcls = T05
    end
    
    should "空のコマンドを作成できる" do
      cmd = @cmdcls.new
      assert_equal(
        4,
        cmd.size
        )
      assert_equal(
        "\x00\x00\x00\x00".unpack("C*").pack("C*"),
        cmd.to_byte
        )
      assert_equal(
        "\x05\x00\x00\x00\xfb\x00\x00\x00\x00".unpack("C*").pack("C*"),
        cmd.to_packet
        )
    end
    
    should "コマンドを作成できる" do
      cmd = @cmdcls.new
      cmd.a = @cmdcls::S01.new
      cmd.a.a = 1
      cmd.a.b = 2
      cmd.a.c = 3
      cmd.a.d = 4
      assert_equal(
        4,
        cmd.size
        )
      assert_equal(
        "\x01\x02\x03\x04".unpack("C*").pack("C*"),
        cmd.to_byte
        )
      assert_equal(
        "\x05\x00\x00\x00\xfb\x01\x02\x03\x04".unpack("C*").pack("C*"),
        cmd.to_packet
        )
    end
  end
end
