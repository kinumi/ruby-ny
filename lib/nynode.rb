#coding: utf-8
require File.dirname(__FILE__) + "/logger"
require File.dirname(__FILE__) + "/consts"
require "socket"
require "rubygems"
require "rc4"

#
# Ny ノード
#
class NyNode
  attr_accessor :host
  attr_accessor :port
  
  def decode(src)
    dat = src[1..-1].each_char.each_slice(2).map(&:join).map(&:hex).pack("C*")
    key_hdr = dat[0]
    enc_addr = dat[1..-1]
    rc4 = RC4.new(key_hdr.chr + NyKeys::NODE_KEY)
    addr = rc4.decrypt(enc_addr)
    @host, @port = addr.split(":")
    @port = @port.to_i
  end
  
  def encode
    addr = "%s:%d" % [@host, @port]
    
    sum = 0
    addr.unpack("C*").each do |v|
      sum += v
    end
    sum &= 0xff
    key = sum.chr + NyKeys::NODE_KEY
    
    rc4 = RC4.new(key)
    return ("@%02x%s" % [sum, rc4.encrypt(addr).unpack("C*").map{|v|"%02x"%v}]).downcase
  end
  
  def connect
    return TCPSocket.new(@host, @port)
  end
  
  def valid?
    con = nil
    data11b = nil
    begin
      timeout(5) do
        logger.debug "connecting to #{@host}:#{@port} (#{encode})"
        con = connect
        data11b = con.recv(11, Socket::MSG_WAITALL)
      end
      logger.debug " -> ok!"
      if decode_hello(data11b).unpack("C*") == [0x01, 0x00, 0x00, 0x00, 0x61]
        return true
      else
        logger.debug " -> but... not ny..."
        return false
      end
    rescue Timeout::Error
      logger.debug " -> timeout..."
      return false
    rescue => e
      logger.debug " -> error... #{e}"
      return false
    ensure
      con.close if con
    end
  end
  
  def decode_hello(data11b)
    recvdat = data11b.unpack("C*")
    dat01 = recvdat.shift(2)
    dat02 = recvdat.shift(4)
    dat03 = recvdat.shift(5)
    key = dat02.pack("C*")
    rc4 = RC4.new(key)
    return rc4.decrypt(dat03.pack("C*"))
  end
end
