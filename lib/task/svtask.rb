#coding: utf-8
$LOAD_PATH << File.dirname(__FILE__) + ".."

require "./common/config"
require "./task/task"
require "socket"

#======================================================================
# サーバータスク
#   クライアントからの接続を待機し、接続があったら通知する
class SvTask < Task
  def run
    @server = TCPServer.open("0.0.0.0", $config[:port])
    #待ち受け部を別スレッド(サブタスク)として起動
    Thread.new do
      begin
        loop do
          sock = @server.accept
          notify :socket_accepted, sock
        end
      ensure
        logger.debug "Task #{self.class}'s SubTask was finished."
      end
    end
    #親処理コール
    super
  end
  
  def on_finish
    @server.close
  end
end
