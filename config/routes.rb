# frozen_string_literal: true

# Block "Zeit buchen" (app/views/my/blocks/_quick_time_entry.html.erb).
# Antworten sind JSON; das Format bleibt bewusst offen: Mit format=json hielte
# Redmine die Anfrage für einen API-Aufruf und ignorierte die Sitzung.
scope 'dashboard_blocks/time_entries' do
  get 'issues', to: 'quick_time_entries#issues', as: 'dashboard_blocks_time_entry_issues'
  get 'activities', to: 'quick_time_entries#activities', as: 'dashboard_blocks_time_entry_activities'
  post '', to: 'quick_time_entries#create', as: 'dashboard_blocks_time_entries'
  delete ':id', to: 'quick_time_entries#destroy', as: 'dashboard_blocks_time_entry', constraints: { id: /\d+/ }
end
