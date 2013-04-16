class Room < ActiveRecord::Base

  attr_accessible :state,  :rows,  :cols, :user_1, :user_2, :current_user, :board_state
end