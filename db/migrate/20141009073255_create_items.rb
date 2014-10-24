class CreateItems < ActiveRecord::Migration
  def self.up
    create_table :items do |t|
      t.string :url
      t.string :tbid
      t.string :title
      t.string :shopid
      t.text :prop

      t.timestamps
    end
  end

  def self.down
    drop_table :items
  end
end
