# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

resources :trackers_statuses_activities do
  collection do
    post 'mass_update'
  end
end
