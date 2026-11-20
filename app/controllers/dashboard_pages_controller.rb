# frozen_string_literal: true

# Dashboards auf "Meine Seite" anlegen, umbenennen, löschen
# (RedmineDashboardBlocks::DashboardPages). Gewechselt wird über
# /my/page?dashboard=<id> (MyPagePatch). Jede Aktion führt zurück auf
# Meine Seite mit dem betroffenen Dashboard.
class DashboardPagesController < ApplicationController
  before_action :require_login

  def create
    id = dashboard_pages.create(params[:name])
    flash[:error] = l(:error_dashboard_blocks_page_not_saved) unless id
    redirect_to my_page_path(dashboard: id || dashboard_pages.active_id)
  end

  def update
    flash[:error] = l(:error_dashboard_blocks_page_not_saved) unless dashboard_pages.rename(params[:id], params[:name])
    redirect_to my_page_path(dashboard: dashboard_pages.active_id)
  end

  def destroy
    dashboard_pages.destroy(params[:id])
    redirect_to my_page_path(dashboard: dashboard_pages.active_id)
  end

  private

  def dashboard_pages
    @dashboard_pages ||= RedmineDashboardBlocks::DashboardPages.new(User.current)
  end
end
