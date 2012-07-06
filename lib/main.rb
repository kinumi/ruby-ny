#!ruby -Ku
#coding: utf-8
require "rubygems"
require File.dirname(__FILE__) + "/logger"
require File.dirname(__FILE__) + "/models"
require File.dirname(__FILE__) + "/nynode"
require File.dirname(__FILE__) + "/nycmdprocessor"
require "timeout"
require "rc4"


class Main
  def execute(enc_node)
    # ノード
    @node = NyNode.new
    @node.decode(enc_node)
    # STAGE開始
    begin
      #CL開始
      t_cl = Thread.new do
        logger.info "Connecting to #{@node.host}:#{@node.port}..."
        @sock = nil
        timeout(5) do
          @sock = @node.connect
          logger.debug " -> OK."
        end
        proc = NyCmdProcessor.new(@sock)
        proc.send_auth
        proc.recv_auth
        t1 = Thread.new{ proc.start_cmdloop_thread }
        t2 = Thread.new{ proc.start_send_thread }
        t1.join
        t2.join
      end
      #SV開始
      t_sv = Thread.new do
        sv = TCPServer.open("0.0.0.0", 20001)
        while true
          Thread.start(sv.accept) do |s|
            print(s.peeraddr, " is accepted\n")
            proc = NyCmdProcessor.new(s)
            proc.send_auth
            proc.recv_auth
            t1 = Thread.new{ proc.start_cmdloop_thread }
            t2 = Thread.new{ proc.start_send_thread }
            t1.join
            t2.join
            sleep 120
          end
        end
      end
      #待合せ
      t_cl.join
      t_sv.join
    rescue Timeout::Error
      logger.error " -> timeout..."
    rescue Errno::ECONNREFUSED
      logger.error " -> refused..."
    end
  end  
end

dbnode = DBNodes.order(:last_connected_at.desc).where(:last_status => true).first
nodestr = dbnode.node
dbnode.delete

nodestr = "@b64ece6f6b7d6eb60bb43e1f3ffe77d59426b861" #local
Main.new.execute(nodestr)
