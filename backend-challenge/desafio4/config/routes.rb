Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  delete "nuke", to: "nuke#destroy"

  root to: redirect("/index.html")
end
