class CreateNodes < ActiveRecord::Migration
  def self.up
    create_table :nodes do |t|
      t.string :enc_addr
      t.string :host
      t.integer :port
      t.integer :speed
      t.string :cluster1
      t.string :cluster2
      t.string :cluster3
      t.integer :pri
      t.datetime :connected_at
      t.timestamps
    end
    add_index :nodes, :enc_addr, :unique => true
  end

  def self.down
    drop_table :nodes
  end
end
