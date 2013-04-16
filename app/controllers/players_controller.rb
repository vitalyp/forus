class PlayersController < ApplicationController

  # Process client incoming connection
  def index
  end

  def client_ready
    @room.game_begin_signal if @room_is_staffed
    render :nothing => true
  end

  # Process new game room creation action:
  def create
    rows, cols = params[:rows], params[:cols]
    # validate game room dimension:
    Room.create_new_room({:rows => rows, :cols => cols, :active_user => @current_user})
    render :nothing => true
  end

  # When logged user close browser tab, or refresh the game page, this action fires:
  def logout_user
    Room.disconnect_player(@current_user)
    render :nothing => true
  end

  def draw_game_board
    @rows = @room.rows
    @cols = @room.cols
    @my_color_class = User.first == @current_user ? COLOR_CLASS_PLAYER_1 : COLOR_CLASS_PLAYER_2
    @my_turn = @room.active_user == @current_user_id
  end

  def player_turn
    if @room.active_user == @current_user_id
      x = params['x'].to_i
      y = params['y'].to_i
      cell_id = x + y*@room.cols.to_i

      cell = User.first == @current_user ? CELL_USER_1 : CELL_USER_2
      @room.set_cell(x, y, @current_user)

      color_class = User.first == @current_user ? COLOR_CLASS_PLAYER_1 : COLOR_CLASS_PLAYER_2

      Pusher[PUSHER_CHANNEL_NAME].trigger(PUSHER_EVENT_PLAYER_TURN, {:message => 'player-turn',
                                                                     :type => 'player-turn',
                                                                     :id => @current_user_id,
                                                                     :cell => [x,y],
                                                                     :cell_id => cell_id,
                                                                     :color_class => color_class })
      next_user_id = User.where('user_id <> ?', @current_user_id).first.user_id
      @room.active_user = next_user_id
      @room.save
    end
    render :nothing => true
  end

  # Action, to send a simple alert message to other connected user
  def alert
    Room.broadcast_alert(params['message'], from: @current_user_id)
  end
  def post_alert
    Room.broadcast_alert(params['message'], from: @current_user_id)
  end

  def moving
  end

  def repair
    User.destroy_all
  end
end
