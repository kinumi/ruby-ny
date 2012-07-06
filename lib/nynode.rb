#coding: utf-8
require File.dirname(__FILE__) + "/logger"
require File.dirname(__FILE__) + "/consts"
require File.dirname(__FILE__) + "/nycommandprocessor"
require "rubygems"
require "socket"
require "rc4"
require "ipaddr"

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
  
  #ノードに接続する
  def connect
    @sock = TCPSocket.new(@host, @port)
    @processor = NyCommandProcessor.new(@sock)
    @processor.on_command_received(0x00) do |cmdobj|
      cmdobj.debug
    end
    @processor.on_command_received(0x01) do |cmdobj|
      cmdobj.debug
    end
    @processor.on_command_received(0x02) do |cmdobj|
      cmdobj.debug
    end
    @processor.on_command_received(0x03) do |cmdobj|
      cmdobj.debug
    end
    @processor.on_command_received(0x04) do |cmdobj|
      logger.debug "command 0x04"
      logger.debug cmdobj.ipaddr
    end
    @processor.on_command_received(0x0d) do |cmdobj|
      logger.debug "command 0x0d"
      logger.debug cmdobj.keys.size
    end
    @processor.on_closed do
      puts "closed... #{id}"
    end
    @processor.recv_auth
    @processor.send_auth
    Thread.new{ @processor.command_loop }
  end
  
  #着信時の処理
  def accept(sock)
    @sock = sock
    @processor = NyCommandProcessor.new(sock)
    @processor.on_command_received(0x00) do |cmdobj|
      cmdobj.debug
    end
    @processor.on_command_received(0x01) do |cmdobj|
      cmdobj.debug
    end
    @processor.on_command_received(0x02) do |cmdobj|
      if cmdobj.bad_port0_flag != 1
        @processor.send_cmd1f
      end
    end
    @processor.on_command_received(0x03) do |cmdobj|
      #cmdobj.debug
    end
    @processor.on_closed do
      puts "accepted connection closed... #{id}"
    end
    @processor.recv_auth
    @processor.send_auth
    Thread.new{ @processor.command_loop }
  end
end
