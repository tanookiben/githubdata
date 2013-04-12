class CreateResults < ActiveRecord::Migration
  def change
    create_table :results do |t|
      t.string :date
      t.integer :hour
      t.string :language
      t.integer :count

      t.timestamps
    end
  end
end
