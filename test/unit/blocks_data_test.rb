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
end
