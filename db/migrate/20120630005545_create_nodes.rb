class CreateNodes < ActiveRecord::Migration
  def self.up
    create_table :nodes do |t|
      t.string :node
      t.string :host
      t.integer :port
      t.datetime :first_connected_at
      t.datetime :last_connected_at
      t.boolean :last_status
      t.timestamps
    end
    add_index :nodes, :node, :unique => true
  end

  def self.down
    drop_table :nodes
  end
end
