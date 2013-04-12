class AddQueryToResults < ActiveRecord::Migration
  def self.up
  	add_column :results, :query, :string
  end

  def self.down
  	remove_column :results, :query
  end
end
