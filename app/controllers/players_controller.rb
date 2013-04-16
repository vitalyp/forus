class PlayersController < ApplicationController

  # Process client incoming connection
  def index
    @room.game_begin_signal if @room_is_staffed || (@room_state == GAME_ROOM_STATE_WAITING && @current_user.nil?)
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
  end

  def draw_game_board
    @rows = Room.last.rows
    @cols = Room.last.cols
    @my_turn = Room.last.current_user == session['session_id']
    @my_color = @my_turn ? 'selected_cell_2' : 'selected_cell_2'
  end

  def player_turn
    x = params['x']
    y = params['y']
    Pusher[PUSHER_CHANNEL_NAME].trigger(PlayersController::CLIENT_EVENT, {:message => 'player-turn', :type => 'player-turn', :id => @session_id})
  end

  # Action, to send a simple alert message to other connected user
  def alert
    Room.broadcast_alert(params['message'], from: self.id)
  end

  def moving
  end
end
