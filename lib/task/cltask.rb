#coding: utf-8
$LOAD_PATH << File.dirname(__FILE__) + "/.."


require "./common/config"
require "./task/task"
require "timeout"
require "socket"

#======================================================================
# クライアントタスク
#   サーバへ接続を試行し、接続結果を通知する
class ClTask < Task
  def on_do_connect(node)
    begin
      sock = nil
      timeout(1) do
        sock = TCPSocket.new(node.host, node.port)
      end
      notify :socket_connected, sock
    rescue Timeout::Error
      notify :socket_error, node
    rescue
      notify :socket_error, node
    end
  end
end
