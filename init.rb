# frozen_string_literal: true

# Dashboard Blocks – Blöcke für "Meine Seite"
#
# Ergänzt Redmines "Meine Seite" um Blöcke, die über den gewohnten Weg
# hinzugefügt, verschoben und entfernt werden ("Hinzufügen" oben auf der
# Seite). Redmine findet sie selbst unter app/views/my/blocks/:
#
#   quick_time_entry        Zeit buchen: Ticket suchen, Dauer, buchen
#   issue_status_tiles      Meine offenen Tickets je Status, überfällig,
#                           diese Woche erledigt
#   open_issues_by_project  Meine offenen Tickets je Hauptprojekt
#   my_week                 Wochenstunden: gebuchte Stunden je Tag gegen ein Wochenziel
#
# Vorhandenes bleibt, wie Redmine es mitbringt (Ticket-Blöcke, Spaltenwahl);
# das Plugin fügt nur hinzu, was fehlt.

Redmine::Plugin.register :redmine_dashboard_blocks do
  name 'Dashboard Blocks'
  author 'stbt.de'
  author_url 'https://stbt.de/'
  description 'Blöcke für Meine Seite: Zeit buchen, Tickets nach Status und Projekt, Wochenstunden.'
  version '1.1.0'
  url 'https://github.com/stbt-de/redmine-dashboard-blocks'
  requires_redmine version_or_higher: '6.0.0'
end

# Hook-Klasse laden (Zeitwerk lädt lib/ nur bei Bedarf); Helfer für die
# Block-Partials auf Meine Seite; Redmines Block "Tickets" mit wählbarer
# Zeilenzahl
RedmineDashboardBlocks::Hooks
MyController.helper(RedmineDashboardBlocks::BlocksHelper)
MyHelper.prepend(RedmineDashboardBlocks::MyHelperPatch) unless MyHelper < RedmineDashboardBlocks::MyHelperPatch

# Mehrfach hinzufügbare Blöcke (wie Redmines "Tickets"): jede Instanz hat
# eigene Einstellungen (my_week, my_week__1, …), z. B. je Mitarbeiter
{ 'my_week' => 5 }.each do |name, max|
  Redmine::MyPage.additional_blocks[name]&.merge!(max_occurs: max)
end
