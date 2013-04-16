class Room < ActiveRecord::Base
  attr_accessible :rows, :cols, :active_user, :state

  before_create :room_should_be_single

  def room_should_be_single
    if Room.count > 0
      #Room.destroy_all
      #raise '[Room::room_should_be_single] room should be single, really. Somebody already created room, but why you was not invited? Hmm.. (this issue should never be happen)'
    end
  end

  def self.create_new_room(attributes)
    #try..catch block to make a safe incoming parameters verification
    begin
      rows = attributes[:rows].to_i
      cols = attributes[:cols].to_i
      isValid = rows.to_i.between?(GAME_ROOM_MIN_DIMENSION, GAME_ROOM_MAX_DIMENSION) && cols.to_i.between?(GAME_ROOM_MIN_DIMENSION, GAME_ROOM_MAX_DIMENSION)
      raise unless isValid
    rescue
      return Pusher[PUSHER_CHANNEL_NAME].trigger(PUSHER_EVENT_ALERT, {message: 'not valid parameters', current_user: attributes[:active_user]})
    end
    #validation passed:
    broadcast_message = 'Game room was created. Waiting for new player..'
    Room.create( rows: attributes[:rows], cols: attributes[:cols], active_user: attributes[:current_user], state: GAME_ROOM_STATE_WAITING )
    Pusher[PUSHER_CHANNEL_NAME].trigger(PUSHER_EVENT_WAIT, {message: broadcast_message})
  end

  def self.disconnect_player(player_user)
    broadcast_message = 'game is interrupted, player left the game room. Your game room is close'
    player_user.destroy
    Room.first.update_attribute('state', GAME_ROOM_STATE_CLOSED)
    Pusher[PUSHER_CHANNEL_NAME].trigger(PUSHER_EVENT_INTERRUPTED, {message: broadcast_message})
    Pusher[PUSHER_CHANNEL_NAME].trigger(PUSHER_EVENT_ALERT, {message: broadcast_message, current_user: player_user.user_id})
  end
  def self.broadcast_alert(message, from)
    Pusher[PUSHER_CHANNEL_NAME].trigger(PUSHER_EVENT_ALERT, {message: message, from: from})
  end


  def game_begin_signal
    Room.first.update_attribute('state', GAME_ROOM_STATE_PLAYING)
    Pusher[PUSHER_CHANNEL_NAME].trigger(PUSHER_EVENT_START, {:message => 'game will be started immediately'})
  end
end