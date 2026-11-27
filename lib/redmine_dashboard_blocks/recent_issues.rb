# frozen_string_literal: true

module RedmineDashboardBlocks
  # "Zuletzt bearbeitete Tickets": Tickets, die der Benutzer zuletzt selbst
  # angelegt, geändert oder kommentiert hat – neueste zuerst, offen wie
  # geschlossen, nur sichtbare.
  class RecentIssues
    LIMIT = 10
    # So viele eigene Änderungen werden höchstens durchgesehen (inzwischen
    # unsichtbare Tickets fallen danach noch heraus)
    LOOKBACK = 50

    def initialize(user)
      @user = user
    end

    def issues
      touched = last_touched
      ids = touched.sort_by { |_id, time| time }.reverse.map(&:first)
      visible = Issue.visible(@user).includes(:project, :status).where(id: ids).index_by(&:id)
      ids.filter_map { |id| visible[id] }.first(LIMIT)
    end

    private

    # Ticket-ID → Zeitpunkt der letzten eigenen Bearbeitung
    def last_touched
      touched = Journal.where(user_id: @user.id, journalized_type: 'Issue')
                       .group(:journalized_id)
                       .order(Arel.sql("MAX(#{Journal.table_name}.created_on) DESC"))
                       .limit(LOOKBACK)
                       .maximum(:created_on)

      Issue.where(author_id: @user.id).reorder(created_on: :desc).limit(LOOKBACK)
           .pluck(:id, :created_on).each do |id, created_on|
        touched[id] = [touched[id], created_on].compact.max
      end
      touched
    end
  end
end
