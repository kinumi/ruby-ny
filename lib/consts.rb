#coding: utf-8

#======================================================================
# �Œ�RC4�L�[
module NyKeys
  #�m�[�h�L�[
  NODE_KEY      = %w(70 69 65 77 66 36 61 73 63 78 6c 76).map(&:hex).pack("C*")
  #�v���g�R���F�ؕ�����L�[
  PROTOCOL_KEY  = %w(39 38 37 38 39 61 73 6A).map(&:hex).pack("C*")
end
