#coding: utf-8

require 'test/unit'
require File.dirname(__FILE__) + "/../lib/nycommands.rb"

#数値のみコマンド
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

#固定長文字列入りコマンド
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

#可変長文字列入りコマンド
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

#サブコマンド入りコマンド
class TFF < NyCommand
  class STFF < NyCommand
    def structure
      [
        [:test3_sz, {:type=>:int8}],
        [:test3, {:type=>:string, :size=>:test3_sz}],
      ]
    end
  end
  def structure
    [
      [:test1_sz, {:type=>:int8}],
      [:test1, {:type=>:string, :size=>:test1_sz}],
      [:test2_rpt, {:type=>:int8}],
      [:test2, {:repeat=>:test2_rpt, :type=>STFF}],
    ]
  end
end

#IPアドレス入りコマンド
class TEE < NyCommand
  def structure
    [
      [:ipaddr, {:type=>:ipaddr}]
    ]
  end
end

class TestNyCommand < Test::Unit::TestCase
  def test_T01_1
    cmd = T01.new
    assert_equal(cmd.size, 7)
    assert_equal(cmd.to_byte,   "\x00\x00\x00\x00\x00\x00\x00")
    assert_equal(cmd.to_packet, "\x08\x00\x00\x00\xff\x00\x00\x00\x00\x00\x00\x00")
    
    cmd.a = 1
    cmd.b = 2
    cmd.c = 3
    assert_equal(cmd.size, 7)
    assert_equal(cmd.to_byte,   "\x01\x02\x00\x03\x00\x00\x00")
    assert_equal(cmd.to_packet, "\x08\x00\x00\x00\xff\x01\x02\x00\x03\x00\x00\x00")
  end
  
  def test_T01_2
    cmd = T01.new("\x01\x02\x00\x03\x00\x00\x00")
    assert_equal(cmd.size, 7)
    assert_equal(cmd.to_byte,   "\x01\x02\x00\x03\x00\x00\x00")
    assert_equal(cmd.to_packet, "\x08\x00\x00\x00\xff\x01\x02\x00\x03\x00\x00\x00")
    
    cmd = T01.new("\x01")
    assert_equal(cmd.size, 7)
    assert_equal(cmd.to_byte,   "\x01\x00\x00\x00\x00\x00\x00")
    assert_equal(cmd.to_packet, "\x08\x00\x00\x00\xff\x01\x00\x00\x00\x00\x00\x00")
    
    cmd = T01.new("")
    assert_equal(cmd.size, 7)
    assert_equal(cmd.to_byte,   "\x00\x00\x00\x00\x00\x00\x00")
    assert_equal(cmd.to_packet, "\x08\x00\x00\x00\xff\x00\x00\x00\x00\x00\x00\x00")
    
    cmd = T01.new("\x01\x02\x00\x03\x00\x00\x00\x04")
    assert_equal(cmd.size, 7)
    assert_equal(cmd.to_byte,   "\x01\x02\x00\x03\x00\x00\x00")
    assert_equal(cmd.to_packet, "\x08\x00\x00\x00\xff\x01\x02\x00\x03\x00\x00\x00")
  end

  def test_T02_1
    cmd = T02.new
    assert_equal(cmd.size, 6)
    assert_equal(cmd.to_byte,   "\x00\x00\x00\x00\x00\x00")
    assert_equal(cmd.to_packet, "\x07\x00\x00\x00\xfe\x00\x00\x00\x00\x00\x00")
    
    cmd.a = 1
    cmd.b = "abcde"
    assert_equal(cmd.size, 6)
    assert_equal(cmd.to_byte,   "\x01abcde")
    assert_equal(cmd.to_packet, "\x07\x00\x00\x00\xfe\x01abcde")
    
    cmd.a = 1
    cmd.b = "abcdefg"
    assert_equal(cmd.size, 6)
    assert_equal(cmd.to_byte,   "\x01abcde")
    assert_equal(cmd.to_packet, "\x07\x00\x00\x00\xfe\x01abcde")
    
    cmd.a = 1
    cmd.b = "a"
    assert_equal(cmd.size, 6)
    assert_equal(cmd.to_byte,   "\x01a\x00\x00\x00\x00")
    assert_equal(cmd.to_packet, "\x07\x00\x00\x00\xfe\x01a\x00\x00\x00\x00")
  end
  
  def test_T02_2
    cmd = T02.new("\x01abcde")
    assert_equal(cmd.size, 6)
    assert_equal(cmd.to_byte,   "\x01abcde")
    assert_equal(cmd.to_packet, "\x07\x00\x00\x00\xfe\x01abcde")

    cmd = T02.new("\x01abcdefg")
    assert_equal(cmd.size, 6)
    assert_equal(cmd.to_byte,   "\x01abcde")
    assert_equal(cmd.to_packet, "\x07\x00\x00\x00\xfe\x01abcde")
    
    cmd = T02.new("\x01a")
    assert_equal(cmd.size, 6)
    assert_equal(cmd.to_byte,   "\x01a\x00\x00\x00\x00")
    assert_equal(cmd.to_packet, "\x07\x00\x00\x00\xfe\x01a\x00\x00\x00\x00")
  end

  def test_T03_1
    cmd = T03.new
    assert_equal(cmd.size, 1)
    assert_equal(cmd.to_byte,   "\x00")
    assert_equal(cmd.to_packet, "\x02\x00\x00\x00\xfd\x00")
  end
  
  def test_T03_2
    cmd = T02.new("\x01abcde")
    assert_equal(cmd.size, 6)
    assert_equal(cmd.to_byte,   "\x01abcde")
    assert_equal(cmd.to_packet, "\x07\x00\x00\x00\xfe\x01abcde")

    cmd = T02.new("\x01abcdefg")
    assert_equal(cmd.size, 6)
    assert_equal(cmd.to_byte,   "\x01abcde")
    assert_equal(cmd.to_packet, "\x07\x00\x00\x00\xfe\x01abcde")
    
    cmd = T02.new("\x01a")
    assert_equal(cmd.size, 6)
    assert_equal(cmd.to_byte,   "\x01a\x00\x00\x00\x00")
    assert_equal(cmd.to_packet, "\x07\x00\x00\x00\xfe\x01a\x00\x00\x00\x00")
  end

  def test_parse_TFF
    pct = ""
    pct += "\x05"
    pct += "abcde"
    pct += "\x02"
    pct += "\x01"
    pct += "1"
    pct += "\x03"
    pct += "987"
    cmd = TFF.new(pct)
    assert_equal(cmd.test1_sz, 5)
    assert_equal(cmd.test1, "abcde")
    assert_equal(cmd.test2.class, Array)
    assert_equal(cmd.test2.size, 2)
    assert_equal(cmd.test2[0].test3_sz, 1)
    assert_equal(cmd.test2[0].test3, "1")
    assert_equal(cmd.test2[1].test3_sz, 3)
    assert_equal(cmd.test2[1].test3, "987")
  end
  def test_to_bytes_TFF
    pct = ""
    pct += "\x05"
    pct += "abcde"
    pct += "\x02"
    pct += "\x01"
    pct += "1"
    pct += "\x03"
    pct += "987"
    cmd = TFF.new
    cmd.test1_sz = 5
    cmd.test1 = "abcde"
    cmd.test2_rpt = 2
    cmd.test2 = []
    cmd.test2 << TFF::STFF.new
    cmd.test2[0].test3_sz = 1
    cmd.test2[0].test3 = "1"
    cmd.test2 << TFF::STFF.new
    cmd.test2[1].test3_sz = 3
    cmd.test2[1].test3 = "987"
    assert_equal(cmd.to_byte, pct)
  end
  
  def test_parse_TEE
    pct = ""
    pct += "\x01\x02\x03\x04"
    cmd = TEE.new(pct)
    assert_equal(cmd.ipaddr, "1.2.3.4")
  end
  def test_to_byte_TEE
    pct = ""
    pct += "\x01\x02\x03\x04"
    cmd = TEE.new
    cmd.ipaddr = "1.2.3.4"
    assert_equal(cmd.to_byte, pct)
  end
  
end
