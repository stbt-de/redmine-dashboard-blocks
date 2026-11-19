# frozen_string_literal: true

module RedmineDashboardBlocks
  # Redmines Block "Tickets" (gespeicherte Abfrage):
  #   - Zeilenzahl wählbar (10, 25, 50, alle) statt fest 10, darunter
  #     "10 von 23 · Alle anzeigen"
  #   - ohne gespeicherte Abfrage eine Erklärung statt einer leeren Auswahl
  # Alles andere bleibt Redmines Block – gleiche Partial (my/blocks/issues),
  # gleiche Spaltenwahl und Sortierung.
  #
  # Nachgebildet ist nur MyHelper#render_issuequery_block (Redmine 6.0–7.0
  # identisch). Die eigenen Partials liegen bewusst nicht unter my/blocks:
  # Redmine hielte jede Datei dort für einen eigenen Block ("Hinzufügen").
  module MyHelperPatch
    ROWS = %w[10 25 50 all].freeze
    DEFAULT_ROWS = '10'
    # "alle" mit Obergrenze: Meine Seite soll nicht an einer riesigen
    # Abfrage hängen
    ALL_LIMIT = 500

    def self.rows(value)
      ROWS.include?(value.to_s) ? value.to_s : DEFAULT_ROWS
    end

    def self.limit(value)
      rows(value) == 'all' ? ALL_LIMIT : rows(value).to_i
    end

    def render_issuequery_block(block, settings)
      query = IssueQuery.visible.find_by_id(settings[:query_id])
      unless query
        return render(partial: 'dashboard_blocks/issue_query_selection',
                      locals: { queries: IssueQuery.visible.sorted, block: block, settings: settings })
      end

      query.column_names = settings[:columns] if settings[:columns].present?
      query.sort_criteria = settings[:sort] if settings[:sort].present?
      issues = query.issues(limit: MyHelperPatch.limit(settings[:rows]))
      locals = { query: query, issues: issues, block: block, settings: settings }

      render(partial: 'my/blocks/issues', locals: locals) +
        render(partial: 'dashboard_blocks/issue_query_rows', locals: locals)
    end
  end
end
