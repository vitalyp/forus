class CreateRoom < ActiveRecord::Migration
  def change
    create_table :rooms do |t|
      t.string :state
      t.string :rows
      t.string :cols
      t.string :current_user
      t.string :board_state
      t.string :user_1
      t.string :user_2
      t.timestamps
    end
  end
end