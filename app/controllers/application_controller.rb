# Background controller for `foRus` application
class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :check_user_permission

  # Session initializing:
  def check_user_permission
    # Postmark secrets placed at config/initializers/postmark.rb
    @room = Room.first
    @room_state = @room ? @room.state : nil
    Pusher.app_id = PUSHER_APP_ID
    Pusher.key = PUSHER_API_KEY
    Pusher.secret = PUSHER_SECRET_KEY

    # terminate Game Room if game ended
    Room.destroy_all if @room_state == GAME_ROOM_STATE_CLOSED

    # Get user session id
    @current_user_id = session['session_id']

    # if user without session, check only for PUSHER_MAX_GAME_CONNECTION limit
    if session['session_id'].nil?
      return User.count < PUSHER_MAX_GAME_CONNECTION ? true : (render :text => 'Room is full')
    end

    @current_user = User.find_by_user_id(@current_user_id)
    # add user to Game Room, if is is not full
    if @current_user.nil? && User.count < PUSHER_MAX_GAME_CONNECTION
      @current_user = User.create(:user_id => @current_user_id)
    end

    # If Game Room is staffed, game can be started immediately
    @room_is_staffed = User.count == PUSHER_MAX_GAME_CONNECTION && !@room.nil?

    # Disconnect guest, to be sure that unregistered user can not access the Game Room.
    (render :text => 'Room is full' and return false) unless @current_user
  end
end