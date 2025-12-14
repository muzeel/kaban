root "projects#index"
devise_for :users

resources :projects do
  resources :tasks, only: [:new, :create] do
    patch :move, on: :member
  end
  resources :invitations, only: [:new, :create]
end
resources :tasks, only: [:show, :edit, :update, :destroy] do
  resources :comments, only: :create
end
namespace :admin do
  root "dashboard#index"
  resources :users
end
