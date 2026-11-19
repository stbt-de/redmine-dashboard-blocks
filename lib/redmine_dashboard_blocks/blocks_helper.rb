# frozen_string_literal: true

module RedmineDashboardBlocks
  # Helfer für die Block-Partials (app/views/my/blocks/_*.html.erb)
  module BlocksHelper
    # Projekt als kleine Kachel: Icon aus redmine_project_icons, wenn das
    # Plugin installiert ist und für das Projekt eins gilt; sonst der
    # Anfangsbuchstabe auf neutraler Fläche
    def dashboard_blocks_project_tile(project, size: 20)
      if respond_to?(:project_icon_tag)
        icon = project_icon_tag(project, size: size)
        return icon if icon.present?
      end

      content_tag(:span, project.name.to_s.strip[0].to_s.upcase,
                  class: 'dashboard-blocks-project-tile', style: "--dashboard-blocks-tile-size: #{size.to_i}px",
                  'aria-hidden': 'true')
    end

    # Stunden wie in Redmine formatiert ("1:30 h" bzw. "1.50 h", je nach
    # Einstellung "Zeitspannenformat")
    def dashboard_blocks_hours(hours)
      l_hours_short(hours)
    end

    # Ticketliste mit Filtern (siehe StatusTiles.filters)
    def dashboard_blocks_issues_path(filters, project: nil)
      project ? project_issues_path(project, filters) : issues_path(filters)
    end
  end
end
