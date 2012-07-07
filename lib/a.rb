#!ruby -Ku
#coding: utf-8

require "rubygems"
require File.dirname(__FILE__) + "/logger"
require File.dirname(__FILE__) + "/config"
require File.dirname(__FILE__) + "/models"
require File.dirname(__FILE__) + "/nynode"
require "socket"

if ARGV[0]
  $config[:port] = ARGV[0].to_i
end

t_sv = Thread.new do
  sv = TCPServer.open("0.0.0.0", $config[:port])
  while true
    Thread.start(sv.accept) do |s|
      logger.debug "#{s.peeraddr} is accepted."
      node = NyNode.new(:host => s.peeraddr[3], :port => s.peeraddr[1])
      node.accept(s)
    end
  end
end

dbnode = DBNodes.order(:last_connected_at.desc).where(:last_status => true).first
nodestr = dbnode.node
#dbnode.delete

node = NyNode.new(:enc_addr=>dbnode.node)
node.connect

sleep 1000

