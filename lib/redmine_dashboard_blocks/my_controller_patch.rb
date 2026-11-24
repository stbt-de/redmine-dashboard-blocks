# frozen_string_literal: true

module RedmineDashboardBlocks
  # Meine Seite: /my/page?dashboard=<id> wechselt das Dashboard, bevor
  # Redmine Anordnung und Blöcke liest. Ohne Parameter bleibt das zuletzt
  # gewählte – auch für Hinzufügen, Verschieben und Blockeinstellungen, die
  # Redmine ohne diesen Parameter aufruft.

  module MyControllerPatch
    def self.included(base)
      base.before_action :switch_dashboard_page, only: :page
    end

    private

    def switch_dashboard_page
      return if params[:dashboard].blank?

      DashboardPages.new(User.current).switch(params[:dashboard])
    end
  end
end
