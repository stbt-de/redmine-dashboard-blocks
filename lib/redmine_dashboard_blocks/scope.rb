# frozen_string_literal: true

module RedmineDashboardBlocks
  # Gemeinsame Abfragen der Blöcke
  module Scope
    module_function

    # "Mir zugewiesen" wie in Redmine: der Benutzer und seine Gruppen
    def assignee_ids(user)
      [user.id] + user.group_ids
    end

    # Offene, sichtbare Tickets, die dem Benutzer (oder seiner Gruppe)
    # zugewiesen sind
    def open_assigned(user)
      Issue.visible(user).open.where(assigned_to_id: assignee_ids(user))
    end

    # Erster Tag der laufenden Woche nach Redmines Einstellung "Woche beginnt
    # am" (leer: Sprache des Benutzers); 1 = Montag … 7 = Sonntag
    def week_start(date)
      first = Setting.start_of_week.presence || ::I18n.t(:general_first_day_of_week, default: '1')
      date - ((date.cwday - first.to_i) % 7)
    end
  end
end
