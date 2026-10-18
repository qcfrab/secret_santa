Rails.application.routes.draw do
  resources :wishes
  devise_for :users, path: ''

  resources :events, only: %i[index show new create] do
    post :draw, on: :member
  end
  get  "join/:code", to: "joins#show",   as: :join
  post "join/:code", to: "joins#create"
  resources :assignments, only: :show do
    resources :messages, only: :create
  end

  root 'home#index'
end