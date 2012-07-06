#coding: utf-8
require File.dirname(__FILE__) + "/logger"
require File.dirname(__FILE__) + "/consts"
require File.dirname(__FILE__) + "/models"
require File.dirname(__FILE__) + "/nynode"
require File.dirname(__FILE__) + "/nycommands"
require "rubygems"
require "rc4"

#======================================================================
# Nyプロトコルコマンド処理機
class NyCommandProcessor
  def initialize(sock)
    @sock = sock
    @rc4_proto1 = RC4.new(NyKeys::PROTOCOL_KEY)
    @rc4_proto2 = RC4.new(NyKeys::PROTOCOL_KEY)
    @key_my1 = [rand(256), rand(256), rand(256), rand(256)].pack("C*")
    @rc4_my1 = RC4.new(prepare_key(@key_my1))
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
        @key_1st = @sock.recv(4, Socket::MSG_WAITALL).tap{|v|chk(v)}
        @rc4_1st = RC4.new(prepare_key(@key_1st))
      end
      #バージョン限定切断要求
      begin
        @rc4_1st.decrypt(@sock.recv(5, Socket::MSG_WAITALL).tap{|v|chk(v)})
      end
      #プロトコルヘッダ
      begin
        cmdsz   = @rc4_1st.decrypt(@sock.recv(4, Socket::MSG_WAITALL).tap{|v|chk(v)}).unpack("V*").first
        cmd     = @rc4_1st.decrypt(@sock.recv(cmdsz, Socket::MSG_WAITALL).tap{|v|chk(v)})
        cmdno   = cmd.bytes.first
        if cmdno == 0x00 && @callback_tbl[cmdno]
          cmdobj = NyCommand00.new(@rc4_proto1.decrypt(cmd[1..-1]))
          @callback_tbl[cmdno].call(cmdobj)
        end
      end
      # RC4キー変更
      begin
        @key_2nd = update_key(@key_1st)
        @rc4_2nd = RC4.new(prepare_key(@key_2nd))
      end
      # コマンド1,2,3
      begin
        #1
        cmdsz   = @rc4_2nd.decrypt(@sock.recv(4, Socket::MSG_WAITALL).tap{|v|chk(v)}).unpack("V*").first
        cmd     = @rc4_2nd.decrypt(@sock.recv(cmdsz, Socket::MSG_WAITALL).tap{|v|chk(v)})
        cmdno   = cmd.bytes.first
        if cmdno == 0x01 && @callback_tbl[cmdno]
          cmdobj = NyCommand01.new(cmd[1..-1])
          @callback_tbl[cmdno].call(cmdobj)
        end
        #2
        cmdsz   = @rc4_2nd.decrypt(@sock.recv(4, Socket::MSG_WAITALL).tap{|v|chk(v)}).unpack("V*").first
        cmd     = @rc4_2nd.decrypt(@sock.recv(cmdsz, Socket::MSG_WAITALL).tap{|v|chk(v)})
        cmdno   = cmd.bytes.first
        cmdpyld = cmd[1..-1]
        if cmdno == 0x02 && @callback_tbl[cmdno]
          cmdobj = NyCommand02.new(cmd[1..-1])
          @callback_tbl[cmdno].call(cmdobj)
        end
        #3
        cmdsz   = @rc4_2nd.decrypt(@sock.recv(4, Socket::MSG_WAITALL).tap{|v|chk(v)}).unpack("V*").first
        cmd     = @rc4_2nd.decrypt(@sock.recv(cmdsz, Socket::MSG_WAITALL).tap{|v|chk(v)})
        cmdno   = cmd.bytes.first
        cmdpyld = cmd[1..-1]
        if cmdno == 0x03 && @callback_tbl[cmdno]
          cmdobj = NyCommand03.new(cmd[1..-1])
          @callback_tbl[cmdno].call(cmdobj)
        end
      end
    rescue
      if @callback_tbl[:closed]
        @callback_tbl[:closed].call
      end
    end
  end
  
  #認証送信
  def send_auth
    packet = ""
    #キー
    begin
      packet += [rand(256), rand(256)].pack("C*")
      packet += @key_my1
    end
    #バージョン限定切断要求
    begin
      cmd61 = NyCommand61.new
      packet += cmd61.to_packet(@rc4_my1)
    end
    #プロトコルヘッダ
    begin
      cmd00 = NyCommand00.new
      cmd00.ver = 12710
      cmd00.str = "Winny Ver2.0b1  "
      packet += @rc4_my1.encrypt((cmd00.to_packet[0,5] + @rc4_proto2.encrypt(cmd00.to_packet[5..-1])))
    end
    #キー更新
    begin
      @key_my2 = update_key(@key_my1)
      @rc4_my2 = RC4.new(prepare_key(@key_my2))
    end
    #回線速度
    begin
      cmd01 = NyCommand01.new
      cmd01.speed = 120
      packet += cmd01.to_packet(@rc4_my2)
    end
    #コネクション種別
    begin
      cmd02 = NyCommand02.new
      cmd02.link_type = 1
      cmd02.port0_flag = 0
      cmd02.bad_port0_flag = 0
      cmd02.bbs_link_flag = 0
      packet += cmd02.to_packet(@rc4_my2)
    end
    #自ノード情報
    begin
      cmd03 = NyCommand03.new
      cmd03.ipaddr = "192.168.1.5"
      cmd03.port = 20001
      cmd03.ddns_sz = 0
      cmd03.cluster1_sz = 1
      cmd03.cluster2_sz = 1
      cmd03.cluster3_sz = 2
      cmd03.ddns = ""
      cmd03.cluster1 = "t"
      cmd03.cluster2 = "e"
      cmd03.cluster3 = "st"
      packet += cmd03.to_packet(@rc4_my2)
    end
    @sock.write packet
  end
  
  def send_cmd0a
    cmd = NyCommand0a.new
    @sock.write cmd.to_packet(@rc4_2nd)
  end
  def send_cmd1f
    cmd = NyCommand1f.new
    @sock.write cmd.to_packet(@rc4_2nd)
  end
  
  def command_loop
    loop do
      begin
        cmdsz   = @rc4_2nd.decrypt(@sock.recv(4, Socket::MSG_WAITALL).tap{|v|chk(v)}).unpack("V*").first
        cmd     = @rc4_2nd.decrypt(@sock.recv(cmdsz, Socket::MSG_WAITALL).tap{|v|chk(v)})
        cmdno   = cmd.bytes.first
        cmdpyld = cmd[1..-1]
        if @callback_tbl[cmdno]
          class_name = "NyCommand%02x" % cmdno[0]
          if Object.constants.include?(class_name)
            cmdobj = Object.const_get(class_name).new(cmdpyld)
            @callback_tbl[cmdno].call(cmdobj)
          end
        end
      rescue
        if @callback_tbl[:closed]
          @callback_tbl[:closed].call
        end
        break
      end
    end
  end

  def request_defusion_loop
    loop do
      begin
        send_cmd0a
        sleep 30
      rescue
        if @callback_tbl[:closed]
          @callback_tbl[:closed].call
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
