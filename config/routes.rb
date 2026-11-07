Rails.application.routes.draw do
  mount ActionCable.server => "/cable"

  resources :wishes
  devise_for :users, path: ''

  resources :events, only: %i[index show new create destroy] do
    post :draw, on: :member
  end
  get  "join/:code", to: "joins#show",   as: :join
  post "join/:code", to: "joins#create"
  resources :participations, only: :show do
    resources :messages, only: :create
  end

  root 'home#index'
end
