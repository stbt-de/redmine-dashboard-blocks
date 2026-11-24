# frozen_string_literal: true

# Dashboard Blocks – Blöcke für "Meine Seite"
#
# Ergänzt Redmines "Meine Seite" um Blöcke, die über den gewohnten Weg
# hinzugefügt, verschoben und entfernt werden ("Hinzufügen" oben auf der
# Seite). Redmine findet sie selbst unter app/views/my/blocks/:
#
#   issue_status_tiles      Meine offenen Tickets je Status, überfällig,
#                           diese Woche erledigt
#   open_issues_by_project  Meine offenen Tickets je Hauptprojekt
#
# Die Zeit-Blöcke „Zeit buchen“ und „Wochenstunden“ gehören seit 2.0 zum
# Plugin Time Autopilot (gleiche Blocknamen, Anordnung bleibt erhalten).
#
# Dazu mehrere Dashboards je Benutzer, oben als Reiter (DashboardPages).
#
# Vorhandenes bleibt, wie Redmine es mitbringt (Ticket-Blöcke, Spaltenwahl);
# das Plugin fügt nur hinzu, was fehlt.

Redmine::Plugin.register :redmine_dashboard_blocks do
  name 'Dashboard Blocks'
  author 'stbt.de'
  author_url 'https://stbt.de/'
  description 'Blöcke für Meine Seite: Tickets nach Status und Projekt, Tickets mit wählbarer Zeilenzahl; mehrere Dashboards als Reiter.'
  version '2.0.0'
  url 'https://github.com/stbt-de/redmine-dashboard-blocks'
  requires_redmine version_or_higher: '6.0.0'
end

# Hook-Klasse laden (Zeitwerk lädt lib/ nur bei Bedarf); Helfer für die
# Block-Partials auf Meine Seite; Redmines Block "Tickets" mit wählbarer
# Zeilenzahl
RedmineDashboardBlocks::Hooks
MyController.helper(RedmineDashboardBlocks::BlocksHelper)
MyHelper.prepend(RedmineDashboardBlocks::MyHelperPatch) unless MyHelper < RedmineDashboardBlocks::MyHelperPatch

# Mehrere Dashboards: Wechsel per /my/page?dashboard=<id>
MyController.include(RedmineDashboardBlocks::MyControllerPatch) unless MyController < RedmineDashboardBlocks::MyControllerPatch
