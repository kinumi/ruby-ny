#coding: utf-8
$LOAD_PATH << File.dirname(__FILE__) + ".."

require "./common/logger"
require "./common/config"
require "thread"

#======================================================================
# タスクベースクラス
class Task
  @@tasks = []
  @@mutex = Mutex.new

  #コンストラクタ
  def initialize
    @@mutex.synchronize do
      @@tasks << self
    end
    @queue = Queue.new
    @finished = false
  end
  
  #タスク処理
  def run
    begin
      #タスクメインループ
      loop do
        unless dispatch_notify
          logger.debug "Task #{self.class} was finished."
          break
        end
      end
    ensure
      @@mutex.synchronize do
        @@tasks.delete self
      end
    end
  end
  
  #管理しているタスク全てにメッセージを通知する
  def notify(msg, *args)
    @@mutex.synchronize do
      @@tasks.each do |i|
        queue = i.instance_variable_get("@queue")
        queue.enq([msg, *args])
      end
    end
  end
  
  #通知をディスパッチして対応するメソッドをコールする
  def dispatch_notify
    recv = @queue.deq
    if respond_to?("on_#{recv[0].to_s}")
      method("on_#{recv[0].to_s}").call(*recv[1..-1])
    end
    if recv[0] == :finish
      return false
    end
    return true
  end
  
  #一定時間ごとにメッセージを通知するタイマーを起動する
  def create_timer(interval, msg)
    Thread.new do
      begin
        loop do
          sleep interval
          notify msg
        end
      ensure
        logger.debug "Task #{self.class}'s SubTask was finished."
      end
    end
  end
end
