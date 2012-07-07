#coding: utf-8
$LOAD_PATH << File.dirname(__FILE__) + ".."

#======================================================================
# 固定RC4キー
module NyKeys
  #ノードキー
  NODE_KEY      = %w(70 69 65 77 66 36 61 73 63 78 6c 76).map(&:hex).pack("C*")
  #プロトコル認証文字列キー
  PROTOCOL_KEY  = %w(39 38 37 38 39 61 73 6A).map(&:hex).pack("C*")
end
