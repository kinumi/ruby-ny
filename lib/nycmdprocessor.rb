#coding: utf-8
require "rubygems"
require File.dirname(__FILE__) + "/logger"
require File.dirname(__FILE__) + "/consts"
require File.dirname(__FILE__) + "/nynode"
require File.dirname(__FILE__) + "/nycommands"
require File.dirname(__FILE__) + "/models"
require "rc4"
require "kconv"
require "ipaddr_extensions"

#
# Ny プロトコル処理機
#
class NyCmdProcessor
  def initialize(sock)
    @sock = sock
    @rc4_proto1 = RC4.new(NyKeys::PROTOCOL_KEY)
    @rc4_proto2 = RC4.new(NyKeys::PROTOCOL_KEY)
    @key_my1 = [rand(256), rand(256), rand(256), rand(256)].pack("C*")
    @rc4_my1 = RC4.new(prepare_key(@key_my1))
  end
  
  #認証受信
  def recv_auth
    #キー
    begin
      sleep 0.2
      @sock.recv(2, Socket::MSG_WAITALL)
      @key_1st = @sock.recv(4, Socket::MSG_WAITALL)
      @rc4_1st = RC4.new(prepare_key(@key_1st))
    end
    #バージョン限定切断要求
    begin
      sleep 0.2
      @rc4_1st.decrypt(@sock.recv(5, Socket::MSG_WAITALL))
    end
    #プロトコルヘッダ
    begin
      sleep 0.2
      cmdsz   = @rc4_1st.decrypt(@sock.recv(4, Socket::MSG_WAITALL)).unpack("V*").first
      cmd     = @rc4_1st.decrypt(@sock.recv(cmdsz, Socket::MSG_WAITALL))
      cmdno   = cmd[0..0]
      cmdpyld = @rc4_proto1.decrypt(cmd[1..-1])
    end
    # RC4キー変更
    begin
      @key_2nd = update_key(@key_1st)
      @rc4_2nd = RC4.new(prepare_key(@key_2nd))
    end
    # コマンド1,2,3　とりあえず無視
    begin
      sleep 0.2
      #1
      cmdsz   = @rc4_2nd.decrypt(@sock.recv(4, Socket::MSG_WAITALL)).unpack("V*").first
      cmd     = @rc4_2nd.decrypt(@sock.recv(cmdsz, Socket::MSG_WAITALL))
      logger.debug cmd.to_dbg
      sleep 0.2
      #2
      cmdsz   = @rc4_2nd.decrypt(@sock.recv(4, Socket::MSG_WAITALL)).unpack("V*").first
      cmd     = @rc4_2nd.decrypt(@sock.recv(cmdsz, Socket::MSG_WAITALL))
      logger.debug cmd.to_dbg
      sleep 0.2
      #3
      cmdsz   = @rc4_2nd.decrypt(@sock.recv(4, Socket::MSG_WAITALL)).unpack("V*").first
      cmd     = @rc4_2nd.decrypt(@sock.recv(cmdsz, Socket::MSG_WAITALL))
      logger.debug cmd.to_dbg
    end
  end
  
  #認証送信
  def send_auth
    firstpacket = ""
    #キー
    begin
      firstpacket += [rand(256), rand(256)].pack("C*")
      firstpacket += @key_my1
    end
    #バージョン限定切断要求
    begin
      cmd61 = NyCommand61.new
      cmd61.debug
      firstpacket += cmd61.to_packet(@rc4_my1)
    end
    #プロトコルヘッダ
    begin
      cmd00 = NyCommand00.new
      cmd00.ver = 12710
      cmd00.str = "Winny Ver2.0b1  "
      cmd00.debug
      firstpacket += @rc4_my1.encrypt((cmd00.to_packet[0,5] + @rc4_proto2.encrypt(cmd00.to_packet[5..-1])))
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
      cmd01.debug
      firstpacket += cmd01.to_packet(@rc4_my2)
    end
    #コネクション種別
    begin
      cmd02 = NyCommand02.new
      cmd02.link_type = 0
      cmd02.port0_flag = 0
      cmd02.bad_port0_flag = 0
      cmd02.bbs_link_flag = 0
      cmd02.debug
      firstpacket += cmd02.to_packet(@rc4_my2)
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
      cmd03.debug
      firstpacket += cmd03.to_packet(@rc4_my2)
    end
    #最初のパケット送信
    sleep 0.2
    @sock.write firstpacket
  end
  
  def start_cmdloop
    loop do
      begin
        sleep 0.2
        cmdsz   = @rc4_2nd.decrypt(@sock.recv(4, Socket::MSG_WAITALL)).unpack("V*").first
        cmd     = @rc4_2nd.decrypt(@sock.recv(cmdsz, Socket::MSG_WAITALL))
      rescue
        begin
          cmd1f = NyCommand1f.new
          @sock.write cmd1f.to_packet(@rc4_my2)
          @sock.close
        rescue
        end
      end
    end
  end
  
  
  def start_cmdloop_thread
    loop do
      begin
        sleep 0.2
        cmdsz = @rc4_2nd.decrypt(@sock.recv(4, Socket::MSG_WAITALL)).unpack("V*").first
        unless cmdsz
          sleep 1
          next
        end
        cmd   = @rc4_2nd.decrypt(@sock.recv(cmdsz, Socket::MSG_WAITALL))
        # コマンド判定
        cmdno   = cmd[0..0]
        cmdpyld = cmd[1..-1]
        # コマンドに対する処理実行
        class_name = "NyCommand%02x" % cmdno[0]
        if Object.constants.include?(class_name)
          cmdobj = Object.const_get(class_name).new(cmdpyld)
          if cmdobj.no == 0x04
            Thread.new do
              begin
                ipaddr = IPAddr.new(cmdobj.ipaddr)
                if ipaddr.global?
                  node = NyNode.new
                  node.host = cmdobj.ipaddr
                  node.port = cmdobj.port
                  if DBNodes.where(:node => node.encode).count == 0
                    dbnode = DBNodes.new(:node => node.encode, :host => node.host, :port => node.port)
                    dbnode.last_connected_at = Time.now
                    unless (dbnode.first_connected_at)
                      dbnode.first_connected_at = dbnode.last_connected_at
                    end
                    dbnode.last_status = node.valid?
                    dbnode.save
                  end
                end
              rescue => e
              end
            end
          elsif cmdobj.no == 0x0d
            keys.each do |key|
              Thread.new do
                begin
                  ipaddr = IPAddr.new(key.ipaddr)
                  if ipaddr.global?
                    node = NyNode.new
                    node.host = key.ipaddr
                    node.port = key.port
                    if DBNodes.where(:node => node.encode).count == 0
                      dbnode = DBNodes.new(:node => node.encode, :host => node.host, :port => node.port)
                      dbnode.last_connected_at = Time.now
                      unless (dbnode.first_connected_at)
                        dbnode.first_connected_at = dbnode.last_connected_at
                      end
                      dbnode.last_status = node.valid?
                      dbnode.save
                    end
                  end
                rescue => e
                end
              end
            end
          end
        else
          logger.debug(cmd.to_dbg)
        end
      rescue
      end
    end
  end
  def start_send_thread
    loop do
      begin
        cmd = NyCommand0a.new
        @sock.write cmd.to_packet(@rc4_my2)
        sleep 30
      rescue
      end
    end
  end
  
  def prepare_key(key)
    key = key.gsub(/\0.*/, "")
    key = "\0" if key.size == 0
    return key
  end
  
  def update_key(key)
    key2 = key.unpack("C*")
    key2[0] ^= 0x00 if key2.size >= 1
    key2[1] ^= 0x39 if key2.size >= 2
    key2[2] ^= 0x39 if key2.size >= 3
    key2[3] ^= 0x39 if key2.size >= 4
    key2 = key2.pack("C*")
  end
end