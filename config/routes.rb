Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'main#index'

  # Sessions
  get 'login' => 'sessions#new'
  post 'login' => 'sessions#create'
  # delete 'logout' => 'sessions#destroy'
  get 'logout' => 'sessions#destroy'

  # Customer (Unique - /:id not accessible)
  # signup
  get 'signup' => 'users#new'
  post 'signup' => 'users#create'
  # account <--- ?
  get 'account' => 'users#edit'
  post 'account' => 'users#update'
  # get 'account/password'
  # credit_cards
  # get 'account/credit_cards'

  # Restaurant (Unique - /:id not accessible)
  # register
  get 'register' => 'restaurants#new'
  post 'register' => 'restaurants#create'
  # menu <--?
  # resources :menu_items
  # walk in queue
  # get 'queue' => 'queue#index'
  # get 'queue/login'
  # get 'queue/logout'
  # dashboard
  # get 'dashboard' => 'dashboard#index'
  # get 'dashboard/table'
  # get 'dashboard/schedule'
  # get 'dashboard/service'

  # Public (Restaurants accessible by /:id)<--?
  resources :restaurants, only: [:show] do
    resources :reservations, only: [:new, :create]
    resources :menu_items, only: [:show]
  end

  # routes for Stripe credit cards charges
  resources :charges
end
