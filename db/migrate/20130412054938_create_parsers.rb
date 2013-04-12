class CreateParsers < ActiveRecord::Migration
  def self.up
    create_table :parsers do |t|
    	t.string :parser_type
    	t.string :event_type
    	t.string :date
    	t.string :base_uri, :default => "http://data.githubarchive.org/"

      t.timestamps
    end
  end

  def self.down
  	drop_table :parsers
  end
end
