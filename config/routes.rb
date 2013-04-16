FoRus::Application.routes.draw do

  # define main game controller, that should process main requests and send requests to players

  resources :players do
    collection do
      get :push
      post :create
      post :logout_user
      post :draw_game_board
      post :player_turn
    end

    end

  # default redirect
  root  :to => 'players#index'

end
