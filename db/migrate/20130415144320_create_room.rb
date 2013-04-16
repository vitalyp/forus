# This migration creates game `rooms` table for Rus application
class CreateRoom < ActiveRecord::Migration
  def change
    create_table :rooms do |t|
      t.string :rows
      t.string :cols
      t.string :state
      t.string :active_user
      t.string :grid

      t.timestamps
    end
  end
end