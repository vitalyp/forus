# This migration creates `users` table for Rus application
class AddUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :user_id
      t.string :user_name

      t.string :chat_message
      t.timestamps
    end
  end

end