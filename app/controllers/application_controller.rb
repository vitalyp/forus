# Background controller for `foRus` application

class ApplicationController < ActionController::Base
  before_filter :prepare_user_data
  # Turn on request forgery protection
  protect_from_forgery


  STATE_NONE = 'none'
  STATE_WAITING = 'waiting'
  STATE_PLAYING = 'playing'

  APP_ID = '41800'
  API_KEY = '11a1d71f5a5743153dda'
  SECRET_KEY = '861b97d91d15edbae270'
  CHANNEL_NAME = 'game-room'
  CLIENT_EVENT = 'client-event'

  WAITING = 'client-wait'
  START = 'client-start'


  def prepare_user_data
    @session_id = session['session_id']
    Pusher.app_id = APP_ID
    Pusher.key = API_KEY
    Pusher.secret = SECRET_KEY
  end



end
