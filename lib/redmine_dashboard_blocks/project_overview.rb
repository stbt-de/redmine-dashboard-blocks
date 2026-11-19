# frozen_string_literal: true

module RedmineDashboardBlocks
  # "Meine Tickets nach Projekt": offene, mir zugewiesene Tickets je
  # Hauptprojekt (Unterprojekte zählen zu ihrem obersten sichtbaren
  # Elternprojekt – bei Kundenprojekten also je Kunde).
  class ProjectOverview
    Row = Struct.new(:project, :count, keyword_init: true)

    LIMIT = 8

    def initialize(user)
      @user = user
    end

    def rows
      counts = Scope.open_assigned(@user).group(:project_id).count
      totals = Hash.new(0)
      Project.where(id: counts.keys).each do |project|
        totals[top_visible(project)] += counts[project.id]
      end

      totals.map { |project, count| Row.new(project: project, count: count) }
            .sort_by { |row| [-row.count, row.project.name.downcase] }
            .first(LIMIT)
    end

    private

    # Oberstes Projekt über dem Projekt, das der Benutzer sehen darf (ein
    # privates Hauptprojekt verrät sonst seinen Namen)
    def top_visible(project)
      @top_visible ||= {}
      @top_visible[project.id] ||=
        Project.visible(@user)
               .where("#{Project.table_name}.lft <= ? AND #{Project.table_name}.rgt >= ?", project.lft, project.rgt)
               .reorder(:lft).first || project
    end
  end
end
