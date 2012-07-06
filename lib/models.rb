#coding: utf-8
require File.dirname(__FILE__) + "/logger"
require "rubygems"
require "sequel"

DB = Sequel.sqlite(File.dirname(__FILE__) + "/../db/data/data.db")

class DBNodes < Sequel::Model(:nodes)
  plugin :timestamps, :update_on_create => true
end
