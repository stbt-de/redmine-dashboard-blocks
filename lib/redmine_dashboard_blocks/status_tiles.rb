# frozen_string_literal: true

module RedmineDashboardBlocks
  # Kacheln "Meine Tickets nach Status": je Status der offenen, mir
  # zugewiesenen Tickets eine Kachel, dazu "Überfällig" und "Diese Woche
  # erledigt". Jede Kachel verlinkt die passend gefilterte Ticketliste.
  class StatusTiles
    Tile = Struct.new(:kind, :label, :count, :filters, keyword_init: true) do
      # Überfällige nur dann hervorheben, wenn es welche gibt
      def alert?
        kind == :overdue && count.positive?
      end
    end

    def initialize(user)
      @user = user
    end

    def tiles
      status_tiles + [overdue_tile, closed_this_week_tile]
    end

    # Parameter der Ticketliste: "Zugewiesen an: ich" plus weitere Filter
    #   { status_id: ['=', '3'], due_date: ['<t-', '1'] }
    def self.filters(conditions)
      conditions = { assigned_to_id: ['=', 'me'] }.merge(conditions)
      {
        set_filter: 1,
        f: conditions.keys.map(&:to_s),
        op: conditions.transform_values(&:first),
        v: conditions.reject { |_field, (_operator, *values)| values.empty? }
                     .transform_values { |(_operator, *values)| values }
      }
    end

    private

    def open_scope
      Scope.open_assigned(@user)
    end

    def status_tiles
      counts = open_scope.group(:status_id).count
      IssueStatus.where(id: counts.keys).sorted.map do |status|
        Tile.new(kind: :status, label: status.name, count: counts[status.id],
                 filters: self.class.filters(status_id: ['=', status.id.to_s]))
      end
    end

    def overdue_tile
      count = open_scope.where("#{Issue.table_name}.due_date < ?", @user.today).count
      # "<t-" 1: Abgabedatum vor mehr als einem Tag, also vor heute
      Tile.new(kind: :overdue, label: ::I18n.t(:label_dashboard_blocks_overdue), count: count,
               filters: self.class.filters(status_id: ['o'], due_date: ['<t-', '1']))
    end

    def closed_this_week_tile
      start = Scope.week_start(@user.today)
      from = (@user.time_zone || Time.zone).local(start.year, start.month, start.day)
      count = Issue.visible(@user)
                   .where(assigned_to_id: Scope.assignee_ids(@user))
                   .joins(:status).where(IssueStatus.table_name => { is_closed: true })
                   .where("#{Issue.table_name}.closed_on >= ?", from)
                   .count
      Tile.new(kind: :closed, label: ::I18n.t(:label_dashboard_blocks_closed_this_week), count: count,
               filters: self.class.filters(status_id: ['c'], closed_on: ['w']))
    end
  end
end
