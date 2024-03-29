#coding: utf-8
$LOAD_PATH << File.dirname(__FILE__) + "/../lib"

require "./protocol/nycommands"
require "rubygems"
require "shoulda"

class TestNyCommand < Test::Unit::TestCase
  #========================================================================================================================================
  context "数値のみコマンド" do
    class T01 < NyCommand
      def no
        0xff
      end
      def structure
        [
          [:a, {:type=>:int8}],
          [:b, {:type=>:int16}],
          [:c, {:type=>:int32}],
        ]
      end
    end
    
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
    class T02 < NyCommand
      def no
        0xfe
      end
      def structure
        [
          [:a, {:type=>:int8}],
          [:b, {:type=>:string, :size=>5}],
        ]
      end
    end

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
    class T03 < NyCommand
      def no
        0xfd
      end
      def structure
        [
          [:a, {:type=>:int8}],
          [:b, {:type=>:string, :size=>:a}],
        ]
      end
    end

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
    class T04 < NyCommand
      def no
        0xfc
      end
      def structure
        [
          [:ipaddr, {:type=>:ipaddr}],
        ]
      end
    end

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
    class T05 < NyCommand
      def no
        0xfb
      end
      class S01 < NyCommand
        def structure
          [
            [:a, {:type=>:int8}],
            [:b, {:type=>:int8}],
            [:c, {:type=>:int8}],
            [:d, {:type=>:int8}],
          ]
        end
      end
      def structure
        [
          [:a, {:type=>S01}],
        ]
      end
    end

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
