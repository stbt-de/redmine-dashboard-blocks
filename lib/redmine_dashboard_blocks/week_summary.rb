# frozen_string_literal: true

module RedmineDashboardBlocks
  # "Meine Woche": gebuchte Stunden der laufenden Woche je Tag, Summe gegen
  # ein Wochenziel. Arbeitstage nach Redmines Einstellung "Arbeitsfreie
  # Tage"; ein freier Tag erscheint nur, wenn an ihm gebucht wurde.
  class WeekSummary
    Day = Struct.new(:date, :hours, :today, keyword_init: true)

    DEFAULT_TARGET = 40

    attr_reader :target

    def initialize(user, target: nil)
      @user = user
      @target = target.to_s.tr(',', '.').to_f
      @target = DEFAULT_TARGET unless @target.positive?
    end

    def start
      @start ||= Scope.week_start(@user.today)
    end

    def days
      @days ||= (start..(start + 6)).filter_map do |date|
        hours = hours_by_day[date].to_f
        next if non_working?(date) && hours.zero?

        Day.new(date: date, hours: hours, today: date == @user.today)
      end
    end

    def total
      hours_by_day.values.sum.to_f
    end

    # Ziel je Arbeitstag (für die Höhe der Balken)
    def daily_target
      working = (start..(start + 6)).count { |date| !non_working?(date) }
      working.positive? ? target / working : target
    end

    # Projekt mit den meisten Stunden in dieser Woche (nur sichtbare)
    def top_project
      project_id, hours = entries.group(:project_id).sum(:hours).max_by { |_id, sum| sum }
      return nil unless project_id

      project = Project.visible(@user).find_by(id: project_id)
      project && [project, hours.to_f]
    end

    private

    def entries
      TimeEntry.where(user_id: @user.id, spent_on: start..(start + 6))
    end

    def hours_by_day
      @hours_by_day ||= entries.group(:spent_on).sum(:hours)
    end

    def non_working?(date)
      Array(Setting.non_working_week_days).map(&:to_i).include?(date.cwday)
    end
  end
end
