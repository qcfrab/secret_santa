Rails.application.routes.draw do
  resources :wishes
  devise_for :users, path: ''

  root 'home#index'
end