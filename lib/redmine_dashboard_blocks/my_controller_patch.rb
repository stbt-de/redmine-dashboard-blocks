# frozen_string_literal: true

module RedmineDashboardBlocks
  # Meine Seite: /my/page?dashboard=<id> wechselt das Dashboard, bevor
  # Redmine Anordnung und Blöcke liest. Ohne Parameter bleibt das zuletzt
  # gewählte – auch für Hinzufügen, Verschieben und Blockeinstellungen, die
  # Redmine ohne diesen Parameter aufruft.
  #
  # Blockeinstellungen der Wochenstunden: die Arbeitszeit (work_hours) gehört
  # der gezeigten Person, nicht dem Block. Sie wird vorher herausgenommen und
  # bei der Person gespeichert, sofern der Betrachter das darf.
  module MyControllerPatch
    def self.included(base)
      base.before_action :switch_dashboard_page, only: :page
      base.before_action :save_work_schedules, only: :update_page
    end

    private

    def save_work_schedules
      settings = params[:settings]
      return unless settings.respond_to?(:each_pair)

      settings.each_pair do |block, block_settings|
        next unless block.to_s.match?(/\Amy_week(__\d+)?\z/) && block_settings.respond_to?(:key?)
        next unless block_settings.key?(:work_hours)

        hours = block_settings.delete(:work_hours)
        person = WeekSummary.resolve_user(User.current, block_settings[:user_id])
        next unless WorkSchedule.editable?(User.current, person) && hours.respond_to?(:to_unsafe_h)

        WorkSchedule.new(person).update(hours.to_unsafe_h)
      end
    end

    def switch_dashboard_page
      return if params[:dashboard].blank?

      DashboardPages.new(User.current).switch(params[:dashboard])
    end
  end
end
