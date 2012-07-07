#coding: utf-8
$LOAD_PATH << File.dirname(__FILE__) + ".."

require "./common/config"
require "./protocol/nyconnection"
require "./task/task"
require "socket"

#======================================================================
# ノード管理タスク
#   ノードを管理する
class NodeMngTask < Task
  @uplink_nodes = []
  @downlink_nodes = []
  
  def run
    create_timer(10, :test)
    super
  end
  
  def on_test
    logger.debug("test!")
  end
  
  def on_socket_connected(sock)
    con = NyConnection.new(sock, 0)
    con.send_auth
    con.recv_auth
  end
  
  def on_socket_accepted(sock)
    con = NyConnection.new(sock, 0)
    con.send_auth
    con.recv_auth
  end
end
