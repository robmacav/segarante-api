Rails.application.routes.draw do
  resources :endossos, only: [:create]
  resources :apolices, param: :numero, only: [:index, :show, :create]
  get "up" => "rails/health#show", as: :rails_health_check
end
