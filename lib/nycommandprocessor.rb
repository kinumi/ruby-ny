#coding: utf-8
require File.dirname(__FILE__) + "/common/logger"
require File.dirname(__FILE__) + "/common/config"
require File.dirname(__FILE__) + "/common/consts"
require File.dirname(__FILE__) + "/protocol/nycommands"
require File.dirname(__FILE__) + "/models"
require File.dirname(__FILE__) + "/nynode"
require "rubygems"
require "rc4"

#======================================================================
# Nyプロトコルコマンド処理機
class NyCommandProcessor
  def initialize(sock)
    @sock = sock
    @rc4_rcv_proto = RC4.new(NyKeys::PROTOCOL_KEY)
    @rc4_snd_proto = RC4.new(NyKeys::PROTOCOL_KEY)
    @key_snd1 = [rand(256), rand(256), rand(256), rand(256)].pack("C*")
    @rc4_snd1 = RC4.new(prepare_key(@key_snd1))
    @callback_tbl = {}
  end
  
  #クローズ時のコールバックメソッドを登録する
  def on_closed(&block)
    @callback_tbl[:closed] = block
  end
  
  #コマンド受信時のコールバックメソッドを登録する
  def on_command_received(cmdno, &block)
    @callback_tbl[cmdno] = block
  end
  
  #認証受信
  def recv_auth
    begin
      #キー
      begin
        @sock.recv(2, Socket::MSG_WAITALL).tap{|v|chk(v)}
        @key_rcv1 = @sock.recv(4, Socket::MSG_WAITALL).tap{|v|chk(v)}
        @rc4_rcv1 = RC4.new(prepare_key(@key_rcv1))
      end
      #バージョン限定切断要求
      begin
        @rc4_rcv1.decrypt(@sock.recv(5, Socket::MSG_WAITALL).tap{|v|chk(v)})
      end
      #プロトコルヘッダ
      begin
        cmdsz   = @rc4_rcv1.decrypt(@sock.recv(4, Socket::MSG_WAITALL).tap{|v|chk(v)}).unpack("V*").first
        cmd     = @rc4_rcv1.decrypt(@sock.recv(cmdsz, Socket::MSG_WAITALL).tap{|v|chk(v)})
        cmdno   = cmd.bytes.first
        if cmdno == 0x00 && @callback_tbl[cmdno]
          cmdobj = NyCommand00.new(@rc4_rcv_proto.decrypt(cmd[1..-1]))
          @callback_tbl[cmdno].call(cmdobj)
        end
      end
      # RC4キー変更
      begin
        @key_rcv2 = update_key(@key_rcv1)
        @rc4_rcv2 = RC4.new(prepare_key(@key_rcv2))
      end
      # コマンド1,2,3
      begin
        #1
        cmdsz   = @rc4_rcv2.decrypt(@sock.recv(4, Socket::MSG_WAITALL).tap{|v|chk(v)}).unpack("V*").first
        cmd     = @rc4_rcv2.decrypt(@sock.recv(cmdsz, Socket::MSG_WAITALL).tap{|v|chk(v)})
        cmdno   = cmd.bytes.first
        if cmdno == 0x01 && @callback_tbl[cmdno]
          cmdobj = NyCommand01.new(cmd[1..-1])
          @callback_tbl[cmdno].call(cmdobj)
        end
        #2
        cmdsz   = @rc4_rcv2.decrypt(@sock.recv(4, Socket::MSG_WAITALL).tap{|v|chk(v)}).unpack("V*").first
        cmd     = @rc4_rcv2.decrypt(@sock.recv(cmdsz, Socket::MSG_WAITALL).tap{|v|chk(v)})
        cmdno   = cmd.bytes.first
        cmdpyld = cmd[1..-1]
        if cmdno == 0x02 && @callback_tbl[cmdno]
          cmdobj = NyCommand02.new(cmd[1..-1])
          @callback_tbl[cmdno].call(cmdobj)
        end
        #3
        cmdsz   = @rc4_rcv2.decrypt(@sock.recv(4, Socket::MSG_WAITALL).tap{|v|chk(v)}).unpack("V*").first
        cmd     = @rc4_rcv2.decrypt(@sock.recv(cmdsz, Socket::MSG_WAITALL).tap{|v|chk(v)})
        cmdno   = cmd.bytes.first
        cmdpyld = cmd[1..-1]
        if cmdno == 0x03 && @callback_tbl[cmdno]
          cmdobj = NyCommand03.new(cmd[1..-1])
          @callback_tbl[cmdno].call(cmdobj)
        end
      end
    rescue => e
      if @callback_tbl[:closed]
        @callback_tbl[:closed].call(e)
      end
    end
  end
  
  #認証送信
  def send_auth
    packet = ""
    #キー
    begin
      packet += [rand(256), rand(256)].pack("C*")
      packet += @key_snd1
    end
    #バージョン限定切断要求
    begin
      cmd61 = NyCommand61.new
      packet += cmd61.to_packet(@rc4_snd1)
    end
    #プロトコルヘッダ
    begin
      cmd00 = NyCommand00.new
      cmd00.ver = 12710
      cmd00.str = "Winny Ver2.0b1  "
      packet += @rc4_snd1.encrypt((cmd00.to_packet[0,5] + @rc4_snd_proto.encrypt(cmd00.to_packet[5..-1])))
    end
    #キー更新
    begin
      @key_snd2 = update_key(@key_snd1)
      @rc4_snd2 = RC4.new(prepare_key(@key_snd2))
    end
    #回線速度
    begin
      cmd01 = NyCommand01.new
      cmd01.speed = $config[:speed]
      packet += cmd01.to_packet(@rc4_snd2)
    end
    #コネクション種別
    begin
      cmd02 = NyCommand02.new
      cmd02.link_type = 0
      cmd02.port0_flag = 0
      cmd02.bad_port0_flag = 0
      cmd02.bbs_link_flag = 0
      packet += cmd02.to_packet(@rc4_snd2)
    end
    #自ノード情報
    begin
      cmd03 = NyCommand03.new
      cmd03.ipaddr = $config[:host]
      cmd03.port = $config[:port]
      cmd03.ddns_sz = 0
      cmd03.cluster1_sz = 4
      cmd03.cluster2_sz = 4
      cmd03.cluster3_sz = 4
      cmd03.ddns = ""
      cmd03.cluster1 = "test"
      cmd03.cluster2 = "hoge"
      cmd03.cluster3 = "fuga"
      packet += cmd03.to_packet(@rc4_snd2)
    end
    @sock.write packet
  end
  
  def send_cmd0a
    cmd = NyCommand0a.new
    cmd.debug
    @sock.write cmd.to_packet(@rc4_snd2)
  end
  def send_cmd1f
    cmd = NyCommand1f.new
    @sock.write cmd.to_packet(@rc4_snd2)
  end
  
  def command_loop
    loop do
      begin
        cmdsz   = @rc4_rcv2.decrypt(@sock.recv(4, Socket::MSG_WAITALL).tap{|v|chk(v)}).unpack("V*").first
        cmd     = @rc4_rcv2.decrypt(@sock.recv(cmdsz, Socket::MSG_WAITALL).tap{|v|chk(v)})
        cmdno   = cmd.bytes.first
        cmdpyld = cmd[1..-1]
        if @callback_tbl[cmdno]
          class_name = "NyCommand%02x" % cmdno[0]
          if Object.constants.include?(class_name)
            cmdobj = Object.const_get(class_name).new(cmdpyld)
            @callback_tbl[cmdno].call(cmdobj)
          end
        end
      rescue => e
        if @callback_tbl[:closed]
          @callback_tbl[:closed].call(e)
        end
        break
      end
    end
  end

  def request_defusion_loop
    loop do
      begin
        sleep 30
        send_cmd0a
      rescue => e
        if @callback_tbl[:closed]
          @callback_tbl[:closed].call(e)
        end
        break
      end
    end
  end

  #キーの前処理(\0の処理)
  private
  def prepare_key(key)
    key = key.gsub(/\0.*/, "")
    key = "\0" if key.size == 0
    return key
  end
  
  #キーの更新処理
  private
  def update_key(key)
    key2 = key.unpack("C*")
    key2[0] ^= 0x00 if key2.size >= 1
    key2[1] ^= 0x39 if key2.size >= 2
    key2[2] ^= 0x39 if key2.size >= 3
    key2[3] ^= 0x39 if key2.size >= 4
    key2 = key2.pack("C*")
  end
  
  #受信チェック
  private
  def chk(dat)
    if dat.size == 0
      raise "closed"
    end
  end
end
