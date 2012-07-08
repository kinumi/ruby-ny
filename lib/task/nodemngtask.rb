#coding: utf-8
$LOAD_PATH << File.dirname(__FILE__) + "/.."


require "./common/config"
require "./protocol/nynode"
require "./protocol/nyconnection"
require "./task/task"
require "./models"
require "socket"

#======================================================================
# ノード管理タスク
#   ノードを管理する
class NodeMngTask < Task
  def run
    @uplink_connections = []
    @downlink_connections = []
    create_timer(5, :manage_uplink)
    create_timer(5, :check_link)
    super
  end
  
  def on_manage_uplink
    if @uplink_connections.size < $config[:uplink_max]
      logger.debug nodes = @uplink_connections.map{|v| v.node.enc_addr }
      logger.debug dbnode = DBNodes.exclude(:enc_addr=>nodes).order(:pri.desc).limit(1).first
      if dbnode
        begin
          node = NyNode.new(:enc_addr=>dbnode.enc_addr)
          notify(:do_connect, node)
          dbnode.host = node.host
          dbnode.port = node.port
          dbnode.save
        rescue
          dbnode.pri -= 10
          dbnode.save
        end
      else
        logger.debug "no node!"
      end
    end
  end
  
  def on_check_link
  end
  
  def on_socket_error(node)
    logger.debug "socket error!"
    dbnode = DBNodes.filter(:enc_addr=>node.enc_addr).first
    if dbnode
      dbnode.pri -= 1
      dbnode.save
    end
  end
  
  def on_socket_connected(sock)
    logger.debug "on_socket_connected!"
    con = NyConnection.new(sock, 0)
    con.regist_closed_callback do
      @uplink_connections.delete con
    end
    con.regist_received_callback(0x04) do |cmdobj|
      logger.debug "0x04!"
      begin
        node = NyNode.new(:host=>cmdobj.ipaddr, :port=>cmdobj.port)
        dbnode = DBNodes.filter(:enc_addr=>node.enc_addr).first
        unless dbnode
          dbnode = DBNodes.new
        end
        dbnode.enc_addr = node.enc_addr
        dbnode.host = cmdobj.ipaddr
        dbnode.port = cmdobj.port
        dbnode.speed = cmdobj.speed
        dbnode.cluster1 = cmdobj.cluster1.toutf8
        dbnode.cluster2 = cmdobj.cluster2.toutf8
        dbnode.cluster3 = cmdobj.cluster3.toutf8
        dbnode.pri = 0
        dbnode.save
      rescue
      end
    end
    con.regist_received_callback(0x0d) do |cmdobj|
      logger.debug "0x0d!"
      cmdobj.keys.each do |key|
        begin
          node = NyNode.new(:host=>key.ipaddr, :port=>key.port)
          dbnode = DBNodes.filter(:enc_addr=>node.enc_addr).first
          unless dbnode
            dbnode = DBNodes.new
          end
          dbnode.enc_addr = node.enc_addr
          dbnode.host = cmdobj.ipaddr
          dbnode.port = cmdobj.port
          dbnode.speed = cmdobj.speed
          dbnode.cluster1 = cmdobj.cluster1.toutf8
          dbnode.cluster2 = cmdobj.cluster2.toutf8
          dbnode.cluster3 = cmdobj.cluster3.toutf8
          dbnode.pri = 0
          dbnode.save
        rescue
        end
      end
    end
    con.send_auth
    con.recv_auth
    if con.node
      dbnode = DBNodes.filter(:enc_addr=>con.node.enc_addr).first
      if dbnode
        dbnode.speed = con.cmd01.speed
        dbnode.cluster1 = con.cmd03.cluster1.toutf8
        dbnode.cluster2 = con.cmd03.cluster2.toutf8
        dbnode.cluster3 = con.cmd03.cluster3.toutf8
        dbnode.save
      end
      @uplink_connections << con
      Thread.new{ con.command_loop }
    end
  end
  
  def on_socket_accepted(sock)
    logger.debug "on_socket_accepted!"
    con = NyConnection.new(sock, 0)
    con.send_auth
    con.recv_auth
  end
end
