#coding: utf-8
require "logger"

task :default => "test"
begin
  require 'tasks/standalone_migrations'
rescue LoadError => e
  puts "gem install standalone_migrations to get db:migrate:* tasks! (Error: #{e})"
end
require 'rake/testtask'
Rake::TestTask.new do |t|
  t.libs << File.dirname(__FILE__) + "/lib"
end
