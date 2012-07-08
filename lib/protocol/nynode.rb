#coding: utf-8
$LOAD_PATH << File.dirname(__FILE__) + "/.."


require "./common/logger"
require "./common/consts"
require "rubygems"
require "rc4"

#======================================================================
# Nyノード
class NyNode
  attr_reader :enc_addr
  attr_reader :host
  attr_reader :port
  
  def initialize(arg={})
    if arg[:enc_addr]
      @host, @port = decode(arg[:enc_addr])
      @enc_addr = arg[:enc_addr]
    elsif arg[:host] && arg[:port]
      @host, @port = arg[:host], arg[:port]
      @enc_addr = encode(arg[:host], arg[:port])
    else
      raise "Parameter [:enc_addr] or [:host, :port] must be specified."
    end
    raise "invalid address" unless @host.kind_of?(String)
    raise "invalid address" unless @host.split(".").size == 4
    @host.split(".").each do |i|
      raise "invalid address" unless i =~ /^[0-9]+$/
    end
  end
  
  #暗号化アドレスをIPアドレスとポート番号にデコード
  def decode(enc_addr)
    enc_body = enc_addr[1..-1].each_char.each_slice(2).map(&:join).map(&:hex).pack("C*")
    rc4 = RC4.new(enc_body[0].chr + NyKeys::NODE_KEY)
    addr = rc4.decrypt(enc_body[1..-1])
    host, port = addr.split(":")
    return host, port.to_i
  end
  
  #IPアドレスとポート番号を暗号化アドレスにエンコード
  def encode(host, port)
    addr = "%s:%d" % [host, port]
    sum = calc_sum(addr)
    rc4 = RC4.new(sum.chr + NyKeys::NODE_KEY)
    return ("@%02x%s" % [sum, rc4.encrypt(addr).unpack("C*").map{|v|"%02x"%v}.join]).downcase
  end
  
  #暗号化アドレスのチェックサム計算
  def calc_sum(addr)
    sum = 0
    addr.unpack("C*").each do |v|
      sum += v
    end
    return sum & 0xff
  end
end
