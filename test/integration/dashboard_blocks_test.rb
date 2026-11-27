# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

class DashboardBlocksTest < Redmine::IntegrationTest
  include RedmineDashboardBlocks::TestHelper
  fixtures(*RedmineDashboardBlocks::TestHelper::FIXTURES)

  def setup
    @user = User.find(2) # jsmith
    log_user('jsmith', 'jsmith')
  end

  # --- Meine Seite ------------------------------------------------------------

  def test_bloecke_stehen_zur_auswahl
    get '/my/page'
    assert_response :success
    %w[issue_status_tiles open_issues_by_project recent_issues].each do |block|
      assert_select 'select#block-select option[value=?]', block
    end
  end

  def test_meine_seite_zeigt_alle_bloecke
    my_page_blocks(@user, :issue_status_tiles, :open_issues_by_project)
    create_assigned_issue(@user)
    get '/my/page'

    assert_response :success
    assert_select '#block-issue_status_tiles .dashboard-blocks-tile', minimum: 3
    assert_select '#block-open_issues_by_project .dashboard-blocks-project'
    assert_select 'link[href*="dashboard_blocks"]'
    # Zeit-Blöcke gehören seit 2.0 zu Time Autopilot
    assert_select 'select#block-select option[value=quick_time_entry]', 0
  end

  def test_zuletzt_bearbeitete_tickets_als_links
    my_page_blocks(@user, :recent_issues)
    issue = create_assigned_issue(@user)
    Journal.create!(journalized: issue, user: @user, notes: 'Notiz', created_on: 5.minutes.from_now)
    get '/my/page'

    assert_response :success
    assert_select '#block-recent_issues a.dashboard-blocks-recent-issue[href=?]', "/issues/#{issue.id}",
                  text: /##{issue.id} #{issue.subject}/
  end

  def test_block_per_hinzufuegen
    my_page_blocks(@user)
    post '/my/add_block', params: { block: 'issue_status_tiles' }, xhr: true
    assert_response :success
    assert_includes @user.reload.pref.my_page_layout['top'], 'issue_status_tiles'
  end

  # --- Dashboards (Reiter) ----------------------------------------------------

  def test_reiter_anlegen_wechseln_umbenennen_loeschen
    my_page_blocks(@user, :open_issues_by_project)
    get '/my/page'
    assert_select '#my-page .dashboard-blocks-pages .tabs a.selected', text: /Übersicht|Overview/
    assert_select '#dashboard-blocks-page-new input[name=name]'

    post '/my/dashboards', params: { name: 'Team' }
    assert_redirected_to '/my/page?dashboard=2'
    follow_redirect!
    assert_select '.dashboard-blocks-pages .tabs a', 2
    assert_select '.dashboard-blocks-pages .tabs a.selected', text: 'Team'
    assert_select '#block-open_issues_by_project', 0
    assert_select '.dashboard-blocks-page-empty'

    # Hinzufügen landet im gewählten Dashboard
    post '/my/add_block', params: { block: 'issue_status_tiles' }, xhr: true
    get '/my/page?dashboard=1'
    assert_select '#block-open_issues_by_project'
    assert_select '#block-issue_status_tiles', 0
    get '/my/page?dashboard=2'
    assert_select '#block-issue_status_tiles'

    patch '/my/dashboards/2', params: { name: 'Zeiten' }
    follow_redirect!
    assert_select '.dashboard-blocks-pages .tabs a.selected', text: 'Zeiten'

    delete '/my/dashboards/2'
    assert_redirected_to '/my/page?dashboard=1'
    follow_redirect!
    assert_select '.dashboard-blocks-pages .tabs a', 1
    assert_select '#block-open_issues_by_project'
  end

  def test_dashboards_anderer_benutzer_bleiben_unberuehrt
    other = User.find(3)
    other.pref.my_page_layout = { 'top' => ['news'] }
    other.pref.save!
    post '/my/dashboards', params: { name: 'Team' }
    delete '/my/dashboards/1'

    assert_equal ['news'], other.reload.pref.my_page_layout['top']
    assert_nil other.pref[:dashboard_blocks_pages]
  end

  # Ohne gespeicherte Abfrage zeigte Redmines Block "Tickets" nur eine leere
  # Auswahl und "Speichern" – jetzt eine Erklärung mit Link zur Ticketliste
  def test_tickets_block_ohne_abfrage_erklaert_den_weg
    IssueQuery.delete_all
    my_page_blocks(@user, :issuequery)
    get '/my/page'

    assert_select '#block-issuequery .dashboard-blocks-query-selection' do
      assert_select 'select', 0
      assert_select 'a[href=?]', '/issues'
      assert_select 'p', text: /Abfrage speichern|Save query/
    end
  end

  def test_tickets_block_mit_abfrage_bietet_auswahl
    IssueQuery.delete_all
    query = IssueQuery.create!(name: 'Meine offenen', user: @user, visibility: IssueQuery::VISIBILITY_PRIVATE,
                               filters: { 'status_id' => { operator: 'o', values: [''] } })
    my_page_blocks(@user, :issuequery)
    get '/my/page'

    assert_select '#block-issuequery select[name=?] option[value=?]', 'settings[issuequery][query_id]', query.id.to_s
    post '/my/page', params: { settings: { issuequery: { query_id: query.id.to_s } } }, xhr: true
    assert_response :success
    get '/my/page'
    assert_select '#block-issuequery h3', text: /Meine offenen/
  end

  # Partials unter my/blocks hält Redmine für Blöcke – eigene Hilfs-Partials
  # dürfen dort nicht liegen, sonst erscheinen sie unter "Hinzufügen"
  def test_nur_die_eigenen_bloecke_zur_auswahl
    plugin_blocks = Redmine::MyPage.additional_blocks.keys
    assert_equal %w[issue_status_tiles open_issues_by_project recent_issues], plugin_blocks.sort
  end

  def test_tickets_block_zeigt_zehn_und_den_weg_zu_allen
    query = issue_query_for_me
    12.times { create_assigned_issue(@user) }
    my_page_blocks(@user, :issuequery)
    @user.pref.update_block_settings('issuequery', query_id: query.id.to_s)
    @user.pref.save!
    get '/my/page'

    total = Issue.visible(@user).open.where(assigned_to_id: @user.id).count
    assert_select '#block-issuequery tr.issue', 10
    assert_select '#block-issuequery .dashboard-blocks-query-count', text: /10 (von|of) #{total}/
    assert_select '#block-issuequery .dashboard-blocks-query-footer a[href*="/issues"]'
    assert_select '#block-issuequery select[name=?] option[selected][value=?]', 'settings[issuequery][rows]', '10'
  end

  def test_zeilenzahl_waehlen_behaelt_spalten
    query = issue_query_for_me
    30.times { create_assigned_issue(@user) }
    my_page_blocks(@user, :issuequery)
    @user.pref.update_block_settings('issuequery', query_id: query.id.to_s, columns: %w[subject status])
    @user.pref.save!

    post '/my/page', params: { settings: { issuequery: { rows: '25' } } }, xhr: true
    assert_response :success
    assert_equal %w[subject status], @user.reload.pref.my_page_settings('issuequery')[:columns]

    get '/my/page'
    assert_select '#block-issuequery tr.issue', 25
    post '/my/page', params: { settings: { issuequery: { rows: 'all' } } }, xhr: true
    get '/my/page'
    assert_select '#block-issuequery tr.issue', Issue.visible(@user).open.where(assigned_to_id: @user.id).count
    assert_select '#block-issuequery .dashboard-blocks-query-footer a', 0
  end

  def test_unbekannte_zeilenzahl_faellt_auf_zehn
    assert_equal 10, RedmineDashboardBlocks::MyHelperPatch.limit('9999')
    assert_equal 500, RedmineDashboardBlocks::MyHelperPatch.limit('all')
  end

  def test_assets_nur_auf_meiner_seite
    get '/projects/ecookbook'
    assert_select 'link[href*="dashboard_blocks"]', 0
  end

  def issue_query_for_me
    IssueQuery.create!(name: "Meine #{SecureRandom.hex(2)}", user: @user, visibility: IssueQuery::VISIBILITY_PRIVATE,
                       filters: { 'status_id' => { operator: 'o', values: [''] },
                                  'assigned_to_id' => { operator: '=', values: ['me'] } })
  end

end
