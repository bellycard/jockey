Rails.application.routes.draw do
  # omniauth with github
  get 'auth/github/callback', to: 'sessions#create', via: [:get, :post]
  get 'auth/failure', to: redirect('/'), via: [:get, :post]
  get 'signout', to: 'sessions#destroy', as: 'signout', via: [:get, :post]
  post 'github_webhooks/:id', to: 'github_webhooks#webhook'

  root 'homepage#signin'

  mount RailsAdmin::Engine => 'admin', as: 'rails_admin'
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  get 'sanity' => 'status#sanity'

  resources :apps do
    collection do
      get 'available_node'
    end
  end

  resources :builds do
    member do
      get 'logs'
    end
  end

  resources :config_sets

  resources :deploys, only: [:index, :show, :create] do
    member do
      get 'logs'
    end
  end

  resources :environments
  resources :reconciles do
    member do
      get 'logs'
    end
    collection do
      post 'preview'
    end
  end
  resources :workers do
    collection do
      put 'rescale'
      put 'restart', action: 'restart_collection'
    end
    member do
      get 'deploys'
      put 'restart', action: 'restart_member'
    end
  end

  get 'container_update', to: 'container_updates#show'
end
