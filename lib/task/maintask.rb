#coding: utf-8
$LOAD_PATH << File.dirname(__FILE__) + ".."

require "./common/config"
require "./task/task"
require "socket"

#======================================================================
# サーバータスク
#   クライアントからの接続を待機し、接続があったら通知する
class MainTask < Task
  def run
    loop do
      a = gets.chomp
      if a == "end"
        notify :finish
        logger.debug "メインタスク終了"
        break
      else
        puts a
      end
    end
  end  
end
