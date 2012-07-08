#coding: utf-8
$LOAD_PATH << File.dirname(__FILE__) + "/.."


require "logger"

class Array
  def to_dbg
    return self.map{|v|"%02x"%v}.join(" ")
  end
end
class String
  def to_dbg
    return self.unpack("C*").to_dbg
  end
end
class Object
  def logger
    unless @logger
      @logger = Logger.new(STDOUT)
      @logger.level = Logger::DEBUG
    end
    @logger
  end
end
