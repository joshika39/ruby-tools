Rails.application.routes.draw do
  get 'home/index'
  post 'home/set_session'
  root "home#index"
end
