# This migration comes from devcms (originally 20121128132941)
class AddUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :user_id
      t.timestamps
    end
  end

end