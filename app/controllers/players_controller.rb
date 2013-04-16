class PlayersController < ApplicationController

  def draw_game_board
    @rows = Room.last.rows
    @cols = Room.last.cols
    @my_turn = Room.last.current_user == session['session_id']
    @my_color = @my_turn ? "selected_cell_2" : "selected_cell_2"
  end

  def logout_user
    @session_id = session['session_id']
    @user = User.find_by_user_id(@session_id)
    unless @user.nil?
      @user.destroy
      Room.destroy_all
      State.destroy_all

      Pusher.app_id = APP_ID
      Pusher.key = API_KEY
      Pusher.secret = SECRET_KEY
      Pusher[CHANNEL_NAME].trigger(PlayersController::CLIENT_EVENT, {:message => 'player disconnected', :type => 'user-disconnected', :id => @session_id})
    end
  end

  # Create room action
  def create
    Pusher.app_id = APP_ID
    Pusher.key = API_KEY
    Pusher.secret = SECRET_KEY

    rows = params[:rows]
    cols = params[:cols]
    @session_id = session['session_id']

    game_state = State.all.first
    State.create(:state => STATE_WAITING) if game_state.nil?

    Room.destroy_all # if game_state.state != STATE_PLAYING

    Room.create(:state => STATE_WAITING,  :rows => rows,  :cols => cols, :user_1 => @session_id, :user_2 => nil)

    if User.all.size >= 2
      Pusher[CHANNEL_NAME].trigger(PlayersController::START, {:message => 'start'})
      Room.last.update_attribute('current_user', @session_id)
    else
      State.first.update_attribute('state', STATE_WAITING)
      Pusher[CHANNEL_NAME].trigger(PlayersController::WAITING, {:message => 'waiting_users'})
    end

    render :nothing => true
  end

  def player_turn
    x = params['x']
    y = params['y']
    Pusher[CHANNEL_NAME].trigger(PlayersController::CLIENT_EVENT, {:message => 'player-turn', :type => 'player-turn', :id => @session_id})
  end

  def index
    if User.all.size == 2
      render :text => 'Room is full' and return
    end
    Pusher.app_id = APP_ID
    Pusher.key = API_KEY
    Pusher.secret = SECRET_KEY
    @session_id = session['session_id']

    @state = State.all.first
    @state = State.create(:state => STATE_NONE) if @state.nil?

    #cleanup room:
    Room.destroy_all if @state == STATE_NONE

    @user = User.find_by_user_id(@session_id)

    if @user.nil?
      User.create(:user_id => @session_id)
    end

    if User.all.size == 2 && @state.state == STATE_WAITING
      @state.state = STATE_PLAYING
      @state.save!
      Room.last.update_attribute('current_user', @session_id)
      Pusher[CHANNEL_NAME].trigger(PlayersController::START, {:message => 'start'})
      @game_state = STATE_PLAYING
      @room = Room.all.first
    end
  end

  def push
    Pusher.app_id = APP_ID
    Pusher.key = API_KEY
    Pusher.secret = SECRET_KEY
    Pusher[CHANNEL_NAME].trigger(PlayersController::CLIENT_EVENT, {:message => 'hello world'})
  end

  def moving

  end
end
