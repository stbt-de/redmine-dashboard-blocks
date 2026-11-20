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
    %w[quick_time_entry issue_status_tiles open_issues_by_project my_week].each do |block|
      assert_select 'select#block-select option[value=?]', block
    end
  end

  def test_meine_seite_zeigt_alle_bloecke
    my_page_blocks(@user, :quick_time_entry, :issue_status_tiles, :open_issues_by_project, :my_week)
    create_assigned_issue(@user)
    get '/my/page'

    assert_response :success
    assert_select '#block-quick_time_entry .dashboard-blocks-quick-time form'
    assert_select '#block-issue_status_tiles .dashboard-blocks-tile', minimum: 3
    assert_select '#block-open_issues_by_project .dashboard-blocks-project'
    assert_select '#block-my_week .dashboard-blocks-day', minimum: 5
    assert_select 'link[href*="dashboard_blocks"]'
    assert_select 'script[src*="dashboard_blocks"]'
  end

  def test_block_per_hinzufuegen
    my_page_blocks(@user)
    post '/my/add_block', params: { block: 'issue_status_tiles' }, xhr: true
    assert_response :success
    assert_includes @user.reload.pref.my_page_layout['top'], 'issue_status_tiles'
  end

  def test_wochenziel_einstellen
    my_page_blocks(@user, :my_week)
    post '/my/page', params: { settings: { my_week: { target_hours: '32' } } }, xhr: true
    assert_response :success
    get '/my/page'
    assert_select '#block-my_week input[name=?][value=?]', 'settings[my_week][target_hours]', '32.0'
  end

  def test_woche_wechseln_und_mitarbeiter_waehlen
    my_page_blocks(@user, :my_week)
    dlopper = User.find(3)
    get '/my/page'
    assert_select '#block-my_week select[name=?] option[value=?]', 'settings[my_week][user_id]', dlopper.id.to_s
    assert_select '#block-my_week button[name=my_week_start]', 2

    # Vorige Woche: Redmine setzt den Block neu ein, die Woche bleibt erhalten
    previous = RedmineDashboardBlocks::Scope.week_start(@user.today) - 7
    post '/my/page', params: { my_week_start: previous.iso8601, settings: { my_week: { user_id: dlopper.id.to_s } } },
                     xhr: true
    assert_response :success
    assert_equal dlopper.id.to_s, @user.reload.pref.my_page_settings('my_week')[:user_id]
    assert_includes response.body, previous.iso8601
    assert_includes response.body, 'dashboard-blocks-week-current'
    assert_includes response.body, "v%5Buser_id%5D%5B%5D=#{dlopper.id}"
  end

  # Woche je Mitarbeiter: der Block lässt sich mehrfach hinzufügen, jede
  # Instanz merkt sich ihre Person (nach dem Neuladen noch gewählt)
  def test_woche_mehrfach_mit_eigener_person
    my_page_blocks(@user)
    post '/my/add_block', params: { block: 'my_week' }, xhr: true
    post '/my/add_block', params: { block: 'my_week__1' }, xhr: true
    assert_equal %w[my_week my_week__1], @user.reload.pref.my_page_layout.values.flatten.grep(/my_week/).sort

    dlopper = User.find(3)
    post '/my/page', params: { settings: { my_week__1: { user_id: dlopper.id.to_s } } }, xhr: true
    get '/my/page'
    assert_select '#block-my_week h3', text: /\AWochenstunden|\AWeekly hours/
    assert_select '#block-my_week__1 h3', text: /#{dlopper.name}/
    assert_select '#block-my_week select option[selected][value=?]', @user.id.to_s
    assert_select '#block-my_week__1 select[name=?] option[selected][value=?]',
                  'settings[my_week__1][user_id]', dlopper.id.to_s
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
  def test_nur_die_vier_bloecke_zur_auswahl
    plugin_blocks = Redmine::MyPage.additional_blocks.keys
    assert_equal %w[issue_status_tiles my_week open_issues_by_project quick_time_entry], plugin_blocks.sort
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

  # --- Zeit buchen ----------------------------------------------------------

  def test_buchen_mit_stunden_und_minuten
    issue = create_assigned_issue(@user)
    assert_difference -> { TimeEntry.count }, 1 do
      post '/dashboard_blocks/time_entries',
           params: { issue_id: issue.id, hours: '1:30', spent_on: @user.today.to_s,
                     activity_id: TimeEntryActivity.shared.active.first.id, comments: 'Schnell gebucht' }
    end
    assert_response :success

    entry = TimeEntry.order(:id).last
    assert_in_delta 1.5, entry.hours
    assert_equal [issue, @user, 'Schnell gebucht'], [entry.issue, entry.user, entry.comments]
    body = response.parsed_body
    assert_equal entry.id, body['id']
    assert_includes body['message'], "##{issue.id}"
    assert body['undo']
  end

  def test_buchen_ohne_recht_verboten
    Role.find(1).remove_permission!(:log_time)
    issue = create_assigned_issue(@user)
    assert_no_difference -> { TimeEntry.count } do
      post '/dashboard_blocks/time_entries', params: { issue_id: issue.id, hours: '1', spent_on: @user.today.to_s }
    end
    assert_response 403
  end

  def test_buchen_auf_unsichtbares_ticket_verboten
    issue = Issue.create!(project: Project.find(2), tracker: Project.find(2).trackers.first, author: User.find(1),
                          subject: 'Fremd', priority: IssuePriority.first)
    post '/dashboard_blocks/time_entries', params: { issue_id: issue.id, hours: '1', spent_on: @user.today.to_s }
    assert_response 403
  end

  def test_fehlende_dauer_mit_fehler_und_link_zum_formular
    issue = create_assigned_issue(@user)
    post '/dashboard_blocks/time_entries', params: { issue_id: issue.id, hours: '', spent_on: @user.today.to_s }

    assert_response 422
    assert response.parsed_body['errors'].any?
    assert_equal "/issues/#{issue.id}/time_entries/new", response.parsed_body['form_url']
  end

  def test_rueckgaengig_nur_fuer_eigene_buchung
    issue = create_assigned_issue(@user)
    own = create_time_entry(@user, issue, hours: 1, spent_on: @user.today)
    foreign = create_time_entry(User.find(3), issue, hours: 1, spent_on: @user.today)

    delete "/dashboard_blocks/time_entries/#{foreign.id}"
    assert_response 404
    assert TimeEntry.exists?(foreign.id)

    delete "/dashboard_blocks/time_entries/#{own.id}"
    assert_response :success
    assert_not TimeEntry.exists?(own.id)
  end

  def test_suche_liefert_projekt_und_kachel
    issue = create_assigned_issue(@user, subject: 'Kategorieseiten schneller laden')
    get '/dashboard_blocks/time_entries/issues', params: { q: 'kategorieseiten' }

    assert_response :success
    hit = response.parsed_body.detect { |entry| entry['id'] == issue.id }
    assert_equal ['Kategorieseiten schneller laden', issue.project.name], [hit['subject'], hit['project']]
    assert_includes hit['tile'], 'dashboard-blocks-project-tile'
  end

  def test_taetigkeiten_des_projekts
    issue = create_assigned_issue(@user)
    get '/dashboard_blocks/time_entries/activities', params: { issue_id: issue.id }

    assert_response :success
    assert_equal issue.project.activities.map(&:id), response.parsed_body.map { |activity| activity['id'] }
  end

  def issue_query_for_me
    IssueQuery.create!(name: "Meine #{SecureRandom.hex(2)}", user: @user, visibility: IssueQuery::VISIBILITY_PRIVATE,
                       filters: { 'status_id' => { operator: 'o', values: [''] },
                                  'assigned_to_id' => { operator: '=', values: ['me'] } })
  end

  def test_ohne_anmeldung_kein_zugriff
    reset!
    get '/dashboard_blocks/time_entries/issues', params: { q: 'x' }, xhr: true
    assert_response 401
  end
end
