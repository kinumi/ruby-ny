#coding: utf-8
require File.dirname(__FILE__) + "/models"
require File.dirname(__FILE__) + "/nynode"
require "socket"
require "open-uri"
require "logger"
require "parallel"
require "thread"

class NyNodeCollector
  SEEDURL = "http://winny.4th.jp/Noderef.txt"
  
  def initialize
    @mutex = Mutex.new
  end
  
  def execute
    #collect_from_seed
    Parallel.each(DBNodes, :in_threads=>10) do |db_node|
      logger.info "processing #{db_node.host}"
      node = NyNode.new
      node.host = db_node.host
      node.port = db_node.port
      #タイムスタンプ更新
      db_node.last_connected_at = Time.now
      unless (db_node.first_connected_at)
        db_node.first_connected_at = db_node.last_connected_at
      end
      db_node.last_status = node.valid?
      @mutex.synchronize do
        db_node.save
      end
    end
  end
  
  def collect_from_seed
    nodereftxt = nil
    open(SEEDURL){|f| nodereftxt = f.read }
    nodereftxt.each do |line|
      node = NyNode.new
      node.decode(line)
      
      addr = node.host.to_s.split(".").map(&:to_i)
      return unless addr.size == 4
      case
      when addr == [127, 0, 0, 1]
        logger.debug "PrivAddr detected! #{node.host}"
      when addr[0, 1] == [10]
        logger.debug "PrivAddr detected! #{node.host}"
      when addr[0, 1] == [172] && (addr[1] >= 16 || addr[1] <= 31)
        logger.debug "PrivAddr detected! #{node.host}"
      when addr[0,2] == [192, 168]
        logger.debug "PrivAddr detected! #{node.host}"
      else
        if Nodes.where(:node => line).count == 0
          Nodes.new(:node => line, :host => node.host, :port => node.port).save
        end
      end
    end
  end
end

NyNodeCollector.new.execute
