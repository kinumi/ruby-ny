#coding: utf-8
$LOAD_PATH << File.dirname(__FILE__) + "/.."


require "socket"

#======================================================================
# 設定
$config = {
  :host => "192.168.1.210",
  :port => 20111, 
  :speed => 1000.0,
  :cluster1 => "",
  :cluster2 => "",
  :cluster3 => "",
  :uplink_max => 2,
  :downlink_max => 0,
}

BasicSocket.do_not_reverse_lookup = true
