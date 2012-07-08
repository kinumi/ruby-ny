#coding: utf-8
$LOAD_PATH << File.dirname(__FILE__) + "/.."


require "./common/logger"
require "./protocol/nycommand"

#======================================================================
# バージョン限定切断要求
class NyCommand61 < NyCommand
  def no
    0x61
  end
end

#======================================================================
# Winnyプロトコルヘッダ
class NyCommand00 < NyCommand
  def no
    0x00
  end
  def structure
    [
      [:ver, {:type=>:int32}],
      [:str, {:type=>:string, :size=>16}], #TODO とりあえずサイズ固定
    ]
  end
end

#======================================================================
# 回線速度通知
class NyCommand01 < NyCommand
  def no
    0x01
  end
  def structure
    [
      [:speed, {:type=>:float}]
    ]
  end
end

#======================================================================
# コネクション種別通知
class NyCommand02 < NyCommand
  def no
    0x02
  end
  def structure
    [
      [:link_type,      {:type=>:int8}],
      [:port0_flag,     {:type=>:int8}],
      [:bad_port0_flag, {:type=>:int8}],
      [:bbs_link_flag,  {:type=>:int8}],
    ]
  end
end

#======================================================================
# 自ノード情報通知
class NyCommand03 < NyCommand
  def no
    0x03
  end
  def structure
    [
      [:ipaddr,       {:type=>:ipaddr}],
      [:port,         {:type=>:int32}],
      [:ddns_sz,      {:type=>:int8}],
      [:cluster1_sz,  {:type=>:int8}],
      [:cluster2_sz,  {:type=>:int8}],
      [:cluster3_sz,  {:type=>:int8}],
      [:ddns,         {:type=>:string, :size=>:ddns_sz}],
      [:cluster1,     {:type=>:string, :size=>:cluster1_sz}],
      [:cluster2,     {:type=>:string, :size=>:cluster2_sz}],
      [:cluster3,     {:type=>:string, :size=>:cluster3_sz}],
    ]
  end
end

#======================================================================
# 他ノード情報通知
class NyCommand04 < NyCommand
  def no
    0x04
  end
  def structure
    [
      [:ipaddr,       {:type=>:ipaddr}],
      [:port,         {:type=>:int32}],
      [:bbs_port,     {:type=>:int32}],
      [:bbs_flag,     {:type=>:int8}],
      [:speed,        {:type=>:int32}],
      [:cluster1_sz,  {:type=>:int8}],
      [:cluster2_sz,  {:type=>:int8}],
      [:cluster3_sz,  {:type=>:int8}],
      [:cluster1,     {:type=>:string, :size=>:cluster1_sz}],
      [:cluster2,     {:type=>:string, :size=>:cluster2_sz}],
      [:cluster3,     {:type=>:string, :size=>:cluster3_sz}],
    ]
  end
end

#======================================================================
# 拡散クエリ送信要求
class NyCommand0a < NyCommand
  def no
    0x0a
  end
end

#======================================================================
# 検索クエリ
class NyCommand0d < NyCommand
  # ノードデータ
  class NodeData < NyCommand
    def no
      0x0d01
    end
    def structure
      [
        [:ipaddr, {:type=>:ipaddr}],
        [:port,   {:type=>:int16}],
      ]
    end
  end
  # キー情報データ
  class KeyData < NyCommand
    def no
      0x0d02
    end
    def structure
      [
        [:ipaddr,       {:type=>:ipaddr}],
        [:port,         {:type=>:int16}],
        [:bbs_ipaddr,   {:type=>:ipaddr}],
        [:bbs_port,     {:type=>:int16}],
        [:file_size,    {:type=>:int32}],
        [:file_hash,    {:type=>:string, :size=>16}],
        [:file_name_sz, {:type=>:int8}],
        [:file_name_ck, {:type=>:string, :size=>2}],
        [:file_name,    {:type=>:string, :size=>:file_name_sz}],
        [:trip,         {:type=>:string, :size=>11}],
        [:bbs_trip_sz,  {:type=>:int8}],
        [:bbs_trip,     {:type=>:string, :size=>:bbs_trip_sz}],
        [:ttl,          {:type=>:int16}],
        [:block_size,   {:type=>:int32}],
        [:modified_time,{:type=>:int32}],
        [:ignore_flag,  {:type=>:int8}],
        [:version,      {:type=>:int8}],
      ]
    end
  end
  def no
    0x0d
  end
  def structure
    [
      [:response_flag,    {:type=>:int8}],
      [:diffusion_flag,   {:type=>:int8}],
      [:downstream_flag,  {:type=>:int8}],
      [:bbs_flag,         {:type=>:int8}],
      [:query_id,         {:type=>:int32}],
      [:keyword_sz,       {:type=>:int8}],
      [:keyword,          {:type=>:string, :size => :keyword_sz}],
      [:trip,             {:type=>:string, :size => 11}],
      [:nodes_rpt,        {:type=>:int8}],
      [:nodes,            {:type=>NodeData, :repeat=>:nodes_rpt}],
      [:keys_rpt,         {:type=>:int8}],
      [:keys,             {:type=>KeyData, :repeat=>:keys_rpt}],
    ]
  end
end

#======================================================================
# 切断要求
class NyCommand1f < NyCommand
  def no
    0x1f
  end
end
