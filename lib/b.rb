#!ruby -Ku
#coding: utf-8
p $LOAD_PATH << File.dirname(__FILE__)
require "task/maintask"
require "task/cltask"
require "task/svtask"
require "task/nodemngtask"

require "rubygems"
require "socket"

t = []
t << Thread.new{ SvTask.new.run }
t << Thread.new{ ClTask.new.run }
t << Thread.new{ NodeMngTask.new.run }
t << Thread.new{ MainTask.new.run }

t.each do |i|
  i.join
end
