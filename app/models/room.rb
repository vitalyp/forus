class Room < ActiveRecord::Base

  #attr_accessible :state,  :rows,  :cols, :user_1, :user_2, :current_user, :board_state

  scope :has_active, :conditions => {:active => true}

  def validate
    raise 'Room already exists!' unless self.active_flag_valid?
  end

    def active_flag_valid?
      self.active == false ||
          Room.has_active.size == 0 ||
          ( Room.has_active.size == 1 && !self.active_changed?)
    end


end