#coding: utf-8
require File.dirname(__FILE__) + "/logger"
require "kconv"

#======================================================================
# Ny プロトコルコマンド ベースクラス
class NyCommand
  SIZETBL = {
    :int8  => 1,
    :int16 => 2,
    :int32 => 4,
    :float => 4,
    :ipaddr => 4,
  }
  
  #コマンド番号
  #サブクラスで要塞定義
  def no
    -1
  end
  #コマンドデータ構造
  #サブクラスで要塞定義
  def structure
    [
    ]
  end
  
  #コンストラクタ
  def initialize(pyld=nil)
    if pyld
      parse(pyld)
    else
      create_structure
    end
  end
  # サイズ
  def size
    to_byte.size
  end
  #コマンドのパケット化
  def to_packet(encrypter=nil)
    unless encrypter
      packet = [size+1, no].pack("VC") + to_byte
    else
      packet = encrypter.encrypt([size+1].pack("V")) + encrypter.encrypt([no].pack("C") + to_byte)
    end
  end
  #コマンドのバイトデータ化
  def to_byte
    pyldary = []
    structure.each do |i|
      name = i[0]
      type = i[1][:type]
      size = i[1][:size]
      dats = instance_variable_get("@#{name.to_s}")
      unless dats.kind_of?(Array)
        dats = [dats]
      end
      dats.each do |dat|
        # サブコマンド処理
        if type.is_a?(Class) && type.ancestors.include?(NyCommand)
          pyldary += dat.to_byte.unpack("C*")
        # 通常データ処理
        else
          size = decide_size(size, type)
          case type
            when :int8
              dat = 0 unless dat
              dat = [dat]
            when :int16
              dat = 0 unless dat
              dat = [dat].pack("v*").unpack("C*")
            when :int32
              dat = 0 unless dat
              dat = [dat].pack("V*").unpack("C*")
            when :float
              dat = 0 unless dat
              dat = [dat].pack("e*").unpack("C*")
            when :string
              dat = "" unless dat
              dat = dat.unpack("C*")
            when :ipaddr
              dat = "0.0.0.0" unless dat
              dat = dat.split(".").map(&:to_i)
          end
          if dat.size > size
            dat = dat[0..size-1]
          elsif dat.size < size
            dat += [0x00]*(size-dat.size)
          end
          pyldary += dat
        end
      end
    end
    return pyldary.pack("C*")
  end
  #デバッグプリント
  def debug
    logger.debug "COMMAND #{"%02x" % no}"
    structure.each do |i|
      name = i[0]
      type = i[1][:type]
      size = i[1][:size]
      dats = instance_variable_get("@#{name.to_s}")
      unless dats.kind_of?(Array)
        dats = [dats]
      end
      dats.each do |dat|
        # サブコマンド処理
        if type.is_a?(Class) && type.ancestors.include?(NyCommand)
          dat.debug
        # 通常データ処理
        else
          case type
            when :int8
              logger.debug "  #{name} -> #{dat}"
            when :int16
              logger.debug "  #{name} -> #{dat}"
            when :int32
              logger.debug "  #{name} -> #{dat}"
            when :float
              logger.debug "  #{name} -> #{dat}"
            when :string
              logger.debug "  #{name}(bin) -> #{dat.to_dbg}"
              logger.debug "  #{name}(str) -> #{dat.toutf8}"
            when :ipaddr
              logger.debug "  #{name}(str) -> #{dat.toutf8}"
          end
        end
      end
    end
  end

  private
  #バイトデータの解析
  def parse(pyld)
    pyldary = pyld.dup.unpack("C*")
    structure.each do |i|
      repeat = decide_repeat(i[1][:repeat])
      name = i[0]
      type = i[1][:type]
      size = i[1][:size]
      # リピート処理
      dats = []
      repeat.times do |i|
        # サブコマンド処理
        if type.is_a?(Class) && type.ancestors.include?(NyCommand)
          dat = type.new(pyldary.pack("C*"))
          pyldary.shift(dat.size)
          dats << dat
        # 通常データ処理
        else
          size = decide_size(size, type)
          dat = pyldary.shift(size)
          case type
            when :int8
              dat = dat[0]
            when :int16
              dat = dat.pack("C*").unpack("v*")[0]
            when :int32
              dat = dat.pack("C*").unpack("V*")[0]
            when :float
              dat = dat.pack("C*").unpack("e*")[0]
            when :string
              dat = dat.pack("C*")
            when :ipaddr
              dat = dat.map(&:to_s).join(".")
          end
          dats << dat
        end
      end
      if repeat == 1
        instance_variable_set("@#{name.to_s}", dats[0])
      else
        instance_variable_set("@#{name.to_s}", dats)
      end
      self.class.send(:attr_accessor, name)
    end
  end
  #コマンドデータ構造からインスタンス変数、アクセサのみ作成
  def create_structure
    structure.each do |i|
      name = i[0]
      instance_variable_set("@#{name.to_s}", nil)
      self.class.send(:attr_accessor, name)
    end
  end
  #リピート数の決定
  def decide_repeat(repeat)
    if repeat.kind_of?(Symbol)
      repeat = instance_variable_get("@#{repeat.to_s}").to_i
    elsif !repeat
      repeat = 1
    end
    return repeat
  end
  #サイズの決定
  def decide_size(size, type)
    if size.kind_of?(Symbol)
      size = instance_variable_get("@#{size.to_s}").to_i
    elsif !size || size == 0
      size = SIZETBL[type]
    end
    return size
  end
end
