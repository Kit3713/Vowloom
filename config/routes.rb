Rails.application.routes.draw do
  resource :session, only: %i[ new create destroy ]
  resources :passwords, param: :token, only: %i[ new create edit update ]
  resource :setup, controller: "setup", only: %i[ new create ]
  resource :management, controller: "management", only: %i[show update]
  post "management/transfer-ownership", to: "management#transfer_ownership", as: :transfer_management_ownership
  resources :archive_snapshots, only: :index do
    get :export, on: :member
    get :readable_export, on: :member
  end
  get "archive/search", to: "archive_search#show", as: :archive_search
  resources :audit_events, only: :index
  resources :moderation_reports, only: :create
  get "moderation", to: "moderation#index"
  patch "moderation/:content_type/:id", to: "moderation#update", as: :moderate_content
  get "reports", to: "reports#index"
  get "reports/events/:id", to: "reports#event_export", defaults: { format: :csv }, as: :event_report
  get "reports/questionnaires/:id", to: "reports#questionnaire_export", defaults: { format: :csv }, as: :questionnaire_report
  resources :households, only: :create
  resources :invitees, only: :create do
    collection do
      post :import
      get :export
    end
  end
  resources :users, only: :update
  resources :invitation_codes, only: :create
  resource :registration, only: %i[ new create ]
  resource :profile, only: %i[edit update]
  get "community", to: "community#show"
  get "calendar", to: "calendars#show"
  get "feed/:space", to: "feeds#show", as: :feed, constraints: { space: /main|general/ }
  resources :posts, only: %i[create update] do
    resources :comments, only: :create
  end
  resources :events, only: %i[index show create update destroy] do
    get :calendar, on: :member
    patch :rsvp, to: "rsvps#update"
    resources :event_invitations, only: %i[create update destroy]
  end
  resources :questionnaires, only: %i[index show create update] do
    resources :questions, only: %i[create update destroy]
    resource :response, only: :create, controller: "questionnaire_responses"
  end
  resources :registry_collections, only: %i[index create update] do
    resources :registry_items, only: :create
  end
  resources :registry_items, only: :update do
    resources :registry_claims, only: :create
  end
  resources :registry_claims, only: :update
  resources :groups, only: %i[index show create] do
    resources :group_memberships, only: %i[create destroy]
    resources :group_resources, only: %i[create destroy]
    resources :tasks, only: %i[create update] do
      resources :task_comments, only: :create
    end
    resource :chat, only: %i[show create], controller: "group_chats"
  end
  get "gallery", to: "gallery#index"
  resources :albums, only: :create do
    resources :album_exports, only: :create do
      get :download, on: :member
    end
  end
  resources :media_assets, only: %i[create update] do
    get :download, on: :member
  end
  resource :chat, only: %i[show create], controller: "chat"
  get "inbox", to: "couple_inboxes#index", as: :couple_inbox
  post "inbox", to: "couple_inboxes#create"
  get "inbox/:id", to: "couple_inboxes#show", as: :couple_inbox_conversation
  resources :kiosk_displays, only: %i[index create update]
  get "display/:token", to: "public_displays#show", as: :public_display
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "home#index"
end
