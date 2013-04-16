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

  # Process disconnected user
  def self.disconnect_player(player_user)
    broadcast_message = 'game is interrupted, player left the game room. Your game room is close'
    player_user.destroy
    Room.first.update_attribute('state', GAME_ROOM_STATE_CLOSED) unless Room.count == 0
    Pusher[PUSHER_CHANNEL_NAME].trigger(PUSHER_EVENT_INTERRUPTED, {message: broadcast_message})
    Pusher[PUSHER_CHANNEL_NAME].trigger(PUSHER_EVENT_ALERT, {message: broadcast_message, current_user: player_user.user_id})
  end

  # Notification to all
  def self.broadcast_alert(message, from)
    Pusher[PUSHER_CHANNEL_NAME].trigger(PUSHER_EVENT_ALERT, {message: message, from: from})
  end

  # Begin the game event
  def game_begin_signal
    # initialize new game grid
    initialize_grid

    # Update Room:
    room = Room.last
    room.state = GAME_ROOM_STATE_PLAYING
    room.active_user = User.last.user_id
    room.save
    room.initialize_grid
    Pusher[PUSHER_CHANNEL_NAME].trigger(PUSHER_EVENT_START, {:message => 'game will be started immediately'})
  end



  # Initialize game field (grid) with empty cells
  def initialize_grid
    plain_grid_matrix = []
    rows.to_i.times do |y|
      cols.to_i.times do |x|
        plain_grid_matrix.push(CELL_EMPTY)
      end
    end
    self.update_attribute('grid', plain_grid_matrix.join(','))
  end

  # set cell
  def set_cell(x, y, user)
    cell = User.first == user ? CELL_USER_1 : CELL_USER_2
    plain_grid_matrix = grid.split(',')
    plain_grid_matrix[cols.to_i*y+x] = cell
    self.update_attribute('grid', plain_grid_matrix.join(','))

    check_for_winner
  end


  # search for winner in the game
  def check_for_winner
    plain_grid_matrix = grid.split(',')

    result = scan_lines(4)

    game_result = GAME_RESULT_DRAW if plain_grid_matrix.index("#{CELL_EMPTY}").nil? && result == CELL_EMPTY

    if result != CELL_EMPTY
      user_cell_number = result[0]
      user_cells = result[1]
      game_result = user_cell_number.to_i
    end


    case game_result
      when GAME_RESULT_WIN_USER_1
        Pusher[PUSHER_CHANNEL_NAME].trigger(PUSHER_EVENT_GAME_FINISHED, {:message => 'player1 win!', :winner => User.all[0].user_id, :cells => user_cells, :cols => cols.to_i})
      when GAME_RESULT_WIN_USER_2
        Pusher[PUSHER_CHANNEL_NAME].trigger(PUSHER_EVENT_GAME_FINISHED, {:message => 'player2 win!', :winner => User.all[1].user_id, :cells => user_cells, :cols => cols.to_i})
      when GAME_RESULT_DRAW
        Pusher[PUSHER_CHANNEL_NAME].trigger(PUSHER_EVENT_GAME_FINISHED, {:message => 'game draw!', :winner => 'nobody'})
    end

  end

  # Search for number, that appears in line `arg` count
  def scan_lines(line_width)
    plain_grid_matrix = grid.split(',')
    array = plain_grid_matrix.each_slice(cols.to_i).to_a
    width = cols.to_i
    height = rows.to_i

    rows.to_i.times do |y|
      cols.to_i.times do |x|
        next if array[y][x].to_i == CELL_EMPTY
        user_cell_number = array[y][x]
        win   = (array[y][x+1] == user_cell_number && x+1 < width) &&
                (array[y][x+2] == user_cell_number && x+2 < width) &&
                (array[y][x+3] == user_cell_number && x+3 < width)
        return [ user_cell_number, [[x,y],[x+1,y],[x+2,y],[x+3,y]] ] if win

        win   = (array[y+1] && array[y+1][x] == user_cell_number && y+1 < height) &&
                (array[y+2] && array[y+2][x] == user_cell_number && y+2 < height) &&
                (array[y+3] && array[y+3][x] == user_cell_number && y+3 < height)
        return [ user_cell_number, [[x,y],[x,y+1],[x,y+2],[x,y+3]] ] if win

        win   = (array[y+1] && array[y+1][x+1] == user_cell_number && y+1 < height && x+1 < width) &&
                (array[y+2] && array[y+2][x+2] == user_cell_number && y+2 < height && x+2 < width) &&
                (array[y+3] && array[y+3][x+3] == user_cell_number && y+3 < height && x+3 < width)
        return [ user_cell_number, [[x,y],[x+1,y+1],[x+2,y+2],[x+3,y+3]] ] if win

        win   = (array[y+1] && array[y+1][x-1] == user_cell_number && y+1 < height && x-1 >= 0) &&
            (array[y+2] && array[y+2][x-2] == user_cell_number && y+2 < height && x-2 >= 0) &&
            (array[y+3] && array[y+3][x-3] == user_cell_number && y+3 < height && x-3 >= 0)
        return [ user_cell_number, [[x,y],[x-1,y+1],[x-2,y+2],[x-3,y+3]] ] if win
      end
    end
    return CELL_EMPTY
  end

end