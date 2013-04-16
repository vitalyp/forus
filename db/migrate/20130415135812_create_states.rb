# This migration comes from devcms (originally 20121128132941)
class CreateStates < ActiveRecord::Migration
  def change
    create_table :states do |t|
      t.string :state
      t.timestamps
    end
  end

end