# frozen_string_literal: true

# Mehrere Dashboards auf Meine Seite (Reiter); Wechsel per /my/page?dashboard=<id>
scope 'my/dashboards' do
  post '', to: 'dashboard_pages#create', as: 'dashboard_blocks_pages'
  patch ':id', to: 'dashboard_pages#update', as: 'dashboard_blocks_page', constraints: { id: /\d+/ }
  delete ':id', to: 'dashboard_pages#destroy', constraints: { id: /\d+/ }
end
