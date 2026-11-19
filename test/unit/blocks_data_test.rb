# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

class BlocksDataTest < ActiveSupport::TestCase
  include RedmineDashboardBlocks::TestHelper
  fixtures(*RedmineDashboardBlocks::TestHelper::FIXTURES)

  def setup
    @user = User.find(2) # jsmith, Manager in Projekt 1
    User.current = @user
    Issue.where(assigned_to_id: @user.id).update_all(assigned_to_id: nil)
  end

  # --- Status-Kacheln -------------------------------------------------------

  def test_kacheln_zaehlen_offene_tickets_je_status
    create_assigned_issue(@user, status: IssueStatus.find(1))
    create_assigned_issue(@user, status: IssueStatus.find(1))
    create_assigned_issue(@user, status: IssueStatus.find(2))
    create_assigned_issue(@user, status: IssueStatus.find(5)) # geschlossen

    tiles = RedmineDashboardBlocks::StatusTiles.new(@user).tiles.select { |tile| tile.kind == :status }
    assert_equal({ IssueStatus.find(1).name => 2, IssueStatus.find(2).name => 1 },
                 tiles.to_h { |tile| [tile.label, tile.count] })
  end

  def test_ueberfaellig_nur_mit_abgabedatum_vor_heute
    create_assigned_issue(@user, due_date: @user.today - 1, start_date: @user.today - 5)
    create_assigned_issue(@user, due_date: @user.today, start_date: @user.today - 5)
    tile = RedmineDashboardBlocks::StatusTiles.new(@user).tiles.detect { |t| t.kind == :overdue }

    assert_equal 1, tile.count
    assert tile.alert?
  end

  def test_filter_der_kacheln_behalten_zugewiesen_an_mich
    tile = RedmineDashboardBlocks::StatusTiles.new(@user).tiles.detect { |t| t.kind == :overdue }

    assert_equal %w[assigned_to_id status_id due_date], tile.filters[:f]
    assert_equal({ assigned_to_id: '=', status_id: 'o', due_date: '<t-' }, tile.filters[:op])
    assert_equal({ assigned_to_id: ['me'], due_date: ['1'] }, tile.filters[:v])
  end

  def test_diese_woche_erledigt
    issue = create_assigned_issue(@user)
    issue.update!(status: IssueStatus.find(5))
    tile = RedmineDashboardBlocks::StatusTiles.new(@user).tiles.detect { |t| t.kind == :closed }

    assert_equal 1, tile.count
  end

  # --- Nach Projekt ---------------------------------------------------------

  def test_unterprojekte_zaehlen_zum_hauptprojekt
    create_assigned_issue(@user, project: Project.find(1))
    create_assigned_issue(@user, project: Project.find(3)) # Unterprojekt von 1
    rows = RedmineDashboardBlocks::ProjectOverview.new(@user).rows

    assert_equal [[Project.find(1), 2]], rows.map { |row| [row.project, row.count] }
  end

  def test_privates_hauptprojekt_bleibt_verborgen
    # Projekt 5 ist privates Unterprojekt von 1; 1 privat machen, jsmith nur in 5
    project = Project.find(5)
    Member.create!(project: project, principal: @user, role_ids: [1]) unless project.members.exists?(user_id: @user.id)
    Project.find(1).update_column(:is_public, false)
    Member.where(project_id: 1, user_id: @user.id).destroy_all
    create_assigned_issue(@user, project: project)

    rows = RedmineDashboardBlocks::ProjectOverview.new(@user).rows
    assert_equal [project], rows.map(&:project)
  end

  # --- Meine Woche ----------------------------------------------------------

  def test_woche_summiert_je_tag
    issue = Issue.find(1)
    start = RedmineDashboardBlocks::Scope.week_start(@user.today)
    TimeEntry.where(user_id: @user.id).delete_all
    create_time_entry(@user, issue, hours: 2, spent_on: start)
    create_time_entry(@user, issue, hours: 1.5, spent_on: start)
    create_time_entry(@user, issue, hours: 3, spent_on: start - 1) # Vorwoche

    week = RedmineDashboardBlocks::WeekSummary.new(@user)
    assert_in_delta 3.5, week.total
    assert_in_delta 3.5, week.days.first.hours
    assert_equal [Project.find(1), 3.5], week.top_project
  end

  def test_freie_tage_nur_mit_buchung
    with_settings non_working_week_days: %w[6 7], start_of_week: '1' do
      TimeEntry.where(user_id: @user.id).delete_all
      week = RedmineDashboardBlocks::WeekSummary.new(@user)
      assert_equal (1..5).to_a, week.days.map { |day| day.date.cwday }

      create_time_entry(@user, Issue.find(1), hours: 1, spent_on: week.start + 5) # Samstag
      week = RedmineDashboardBlocks::WeekSummary.new(@user)
      assert_equal (1..6).to_a, week.days.map { |day| day.date.cwday }
    end
  end

  def test_wochenziel_mit_komma_und_standard
    assert_in_delta 37.5, RedmineDashboardBlocks::WeekSummary.new(@user, target: '37,5').target
    assert_in_delta 40, RedmineDashboardBlocks::WeekSummary.new(@user, target: '').target
    assert_in_delta 40, RedmineDashboardBlocks::WeekSummary.new(@user, target: '-3').target
  end

  # --- Zeit buchen: Suche ---------------------------------------------------

  def test_suche_nach_nummer_titel_und_projekt
    issue = create_assigned_issue(@user, subject: 'Versandarten nach Gewicht')
    quick = RedmineDashboardBlocks::QuickTimeEntry.new(@user)

    assert_equal issue, quick.search("##{issue.id}").first
    assert_includes quick.search('versandarten gewicht'), issue
    assert_includes quick.search("#{Project.find(1).name} versand"), issue
  end

  def test_suche_ohne_geschlossene_und_ohne_buchungsrecht
    closed = create_assigned_issue(@user, subject: 'Geschlossenes Zielticket', status: IssueStatus.find(5))
    # Projekt 2 (OnlineStore): jsmith ist dort nicht Mitglied, Projekt ist privat
    foreign = Issue.create!(project: Project.find(2), tracker: Project.find(2).trackers.first, author: User.find(1),
                            subject: 'Fremdes Zielticket', priority: IssuePriority.first)
    results = RedmineDashboardBlocks::QuickTimeEntry.new(@user).search('Zielticket')

    assert_not_includes results, closed
    assert_not_includes results, foreign
  end

  def test_zuletzt_gebuchte_tickets_neueste_zuerst
    TimeEntry.where(user_id: @user.id).delete_all
    first = create_assigned_issue(@user)
    second = create_assigned_issue(@user)
    create_time_entry(@user, first, hours: 1, spent_on: @user.today - 2)
    create_time_entry(@user, second, hours: 1, spent_on: @user.today - 1)
    create_time_entry(@user, first, hours: 1, spent_on: @user.today - 3)

    assert_equal [second, first], RedmineDashboardBlocks::QuickTimeEntry.new(@user).recent_issues
  end
end
