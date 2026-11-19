# frozen_string_literal: true

module RedmineDashboardBlocks
  # Stylesheet und Script nur auf "Meine Seite" – dort liegen die Blöcke
  class Hooks < Redmine::Hook::ViewListener
    def view_layouts_base_html_head(context = {})
      controller = context[:controller]
      return '' unless controller.is_a?(MyController) && controller.action_name == 'page'

      safe_join([
        stylesheet_link_tag('dashboard_blocks', plugin: 'redmine_dashboard_blocks'),
        javascript_include_tag('dashboard_blocks', plugin: 'redmine_dashboard_blocks', defer: true)
      ], "\n")
    end
  end
end
