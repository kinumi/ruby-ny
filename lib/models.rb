#coding: utf-8
require "rubygems"
require File.dirname(__FILE__) + "/logger"
require "sequel"

DB = Sequel.sqlite(File.dirname(__FILE__) + "/../db/data/data.db")

class DBNodes < Sequel::Model(:nodes)
  plugin :timestamps, :update_on_create => true
end
