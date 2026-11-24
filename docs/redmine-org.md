# Redmine plugin directory – Dashboard Blocks

Fields for the entry on https://www.redmine.org/plugins (*Register a new plugin*).
Text fields use Redmine's Textile formatting.

## Plugin Name

Dashboard Blocks

## Identifier

redmine_dashboard_blocks

## Description

More useful blocks for Redmine's *My page*, and several dashboards per user.

* *Log time* – find an issue by number, subject or project, pick a duration, log it without leaving the page; undo, recently logged issues.
* *My issues by status* – open issues as tiles per status, plus overdue and closed this week; every tile opens the filtered issue list.
* *My issues by project* – open issues per top-level project (subprojects count towards their parent).
* *Weekly hours* – hours per day against each person's working hours (set per weekday, e.g. Friday 4 h); step through weeks, pick a colleague; can be added up to five times.
* *Several dashboards* – e.g. Overview, Team, Time as tabs above the columns, each with its own blocks and settings.
* Redmine's own *Issues* block: choose 10, 25, 50 or all rows.

Works with any theme; styled for the "Klar theme":https://github.com/stbt-de/redmine-klar-theme. English and German.

## Homepage

https://github.com/stbt-de/redmine-dashboard-blocks

## Code repository

https://github.com/stbt-de/redmine-dashboard-blocks

## Thumbnail

`docs/thumbnail.png` (100 × 100 px; source: `docs/thumbnail.svg`)

## Installation notes

The folder in @plugins/@ must be named <code>redmine_dashboard_blocks</code>.

<pre>
cd /path/to/redmine/plugins
git clone https://github.com/stbt-de/redmine-dashboard-blocks.git redmine_dashboard_blocks
</pre>

Or unpack the release zip from "GitHub releases":https://github.com/stbt-de/redmine-dashboard-blocks/releases into @plugins/@.

Restart Redmine. No database migration is needed. Each user adds the blocks on *My page* via *Add*.

## Plugin version

1.3.0

## Redmine compatibility

Tick: **7.0.x**, **6.1.x**, **6.0.x** (tested; see README → *Tested with*).
Not 7.1.x until it has been tested.

## Updating this entry

On a new release: on redmine.org open the plugin → *Add a version*, enter the version
and the compatible Redmine versions. Change name, description or installation notes
here first, then copy them over.
