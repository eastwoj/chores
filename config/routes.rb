Rails.application.routes.draw do
  devise_for :adults
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Root and main navigation routes
  root "home#index"
  
  # Child kiosk routes
  resources :child_kiosk, only: [:index, :show], path: "kiosk" do
    member do
      patch :complete_chore
      patch :uncomplete_chore
      patch :complete_extra
    end
  end
  
  # Admin routes for parents
  namespace :admin do
    root "dashboard#index"
    resources :dashboard, only: [:index]
    resources :reviews, only: [:index] do
      member do
        patch :approve_chore
        patch :reject_chore
        patch :reset_chore
        patch :approve_extra
        patch :reject_extra
      end
    end
    resources :chores do
      member do
        patch :toggle_active
      end
      collection do
        patch :assign_constant_chore
        delete :remove_constant_assignment
        post :generate_daily_lists
      end
    end
    resources :extras do
      member do
        patch :toggle_active
      end
      collection do
        patch :assign_extra
        delete :remove_extra_assignment
      end
    end
  end

  # Redirect after sign in
  get "/admin", to: "admin/dashboard#index"
end
