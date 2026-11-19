# frozen_string_literal: true

require File.expand_path('../../../test/test_helper', __dir__)

module RedmineDashboardBlocks
  module TestHelper
    FIXTURES = %i[
      projects users email_addresses user_preferences members member_roles roles
      issues issue_statuses trackers projects_trackers enabled_modules enumerations
      time_entries issue_categories versions workflows groups_users
    ].freeze

    # Ticket im Projekt, dem Benutzer zugewiesen (direkt gesetzt: in
    # Unterprojekten ist der Benutzer nicht immer Mitglied)
    def create_assigned_issue(user, project: Project.find(1), status: IssueStatus.find(1), **attributes)
      issue = Issue.create!({
        project: project, tracker: project.trackers.first, author: User.find(1),
        subject: "Testticket #{SecureRandom.hex(3)}", status: status,
        priority: IssuePriority.default || IssuePriority.first
      }.merge(attributes))
      Issue.where(id: issue.id).update_all(assigned_to_id: user.id)
      Issue.find(issue.id)
    end

    def create_time_entry(user, issue, hours:, spent_on:)
      TimeEntry.create!(project: issue.project, issue: issue, user: user, author: user, hours: hours,
                        spent_on: spent_on, activity: TimeEntryActivity.shared.active.first)
    end

    # Meine Seite eines Benutzers nur mit diesen Blöcken
    def my_page_blocks(user, *blocks)
      user.pref.my_page_layout = { 'top' => blocks.map(&:to_s) }
      user.pref.save!
    end
  end
end
