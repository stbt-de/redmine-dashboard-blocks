# Dashboard Blocks – more useful blocks for Redmine's "My page"

Redmine's *My page* is a good place to start the day – but its blocks are mostly lists.
This plugin adds blocks that show at a glance where your issues stand, and lets everyone
keep several dashboards.

> **Time blocks moved.** Since 2.0 the blocks *Log time* and *Weekly hours* are part of
> [Time Autopilot](https://github.com/stbt-de/redmine-time-autopilot), together with
> working hours per weekday and time proposals. See *Upgrading to 2.0* below.

- **My issues by status** – your open issues as tiles per status, plus *Overdue* and
  *Closed this week*. Every tile opens the matching filtered issue list.
- **My issues by project** – your open issues per top-level project; subprojects count
  towards their parent (with customer projects: per customer). Shows project icons when
  [redmine-project-icons](https://github.com/stbt-de/redmine-project-icons) is installed.
The blocks are added, moved and removed like Redmine's own blocks (*My page → Add*).

**Several dashboards** – each user can keep more than one *My page*, e.g. *Overview*,
*Team* and *Time*, shown as tabs above the columns. **+** creates a new, empty dashboard,
the **…** menu renames or deletes the current one (up to ten per user). Every dashboard
has its own blocks, arrangement and block settings, and its own address
(`/my/page?dashboard=2`) for bookmarks. Your existing *My page* becomes the first
dashboard. Dashboards are private to each user.

Technically Redmine keeps working on one page: the plugin swaps the stored arrangement and
block settings when you switch tabs, so adding, moving and configuring blocks work exactly
as before. The tab you used last stays selected – with two browser windows on different
dashboards, changes go to the one selected last.

Redmine's own **Issues** block (a saved query on *My page*) gets two small additions:
the number of rows can be chosen (10, 25, 50 or all instead of always 10), with
"10 of 23 · Show all" below the list; and without any saved query the block explains how
to create one instead of showing an empty selection. Its column selection and sorting
stay Redmine's own. Works with any theme;
[Klar](https://github.com/stbt-de/redmine-klar-theme) is styled for it.

## Screenshots

*Shown with the [Klar theme](https://github.com/stbt-de/redmine-klar-theme) and example data.*

![My page with the blocks](docs/screenshots/my-page.png)

| My page on mobile |
| --- |
| <img src="docs/screenshots/mobile-my-page.png" width="300" alt="My page on mobile"> |

## Installation

The folder in `plugins/` must be named `redmine_dashboard_blocks`.

**Release zip:** download `redmine-dashboard-blocks-v*.zip` from the
[releases](https://github.com/stbt-de/redmine-dashboard-blocks/releases) and unpack it in
the `plugins/` directory (it contains the folder `redmine_dashboard_blocks/`).

**Or clone:**

```
cd /path/to/redmine/plugins
git clone https://github.com/stbt-de/redmine-dashboard-blocks.git redmine_dashboard_blocks
```

Then restart Redmine. No database migration is needed. Each user adds the blocks on
*My page* via *Add*.

To uninstall: remove the blocks from *My page* (or leave them – Redmine skips unknown
blocks), remove the folder and restart Redmine.

### Tested with

| Redmine | Ruby | Rails | Checked |
| --- | --- | --- | --- |
| 7.0.3 | 4.0.10 | 8.1.4 | integration tests; in the browser with the themes Default and Klar (desktop, mobile) |
| 6.1.6 | 3.4.13 | 7.2.4 | integration tests |
| 6.0.12 | 3.3.14 | 7.2.3.2 | integration tests |

The plugin requires Redmine 6.0 or later. The interface is available in English and
German.

## How it works

**Permissions** are Redmine's own: the blocks only count and show issues the user can
see.

**"My issues"** means issues assigned to the user or to one of their groups, as in
Redmine's own *Issues assigned to me*. The week for *Closed this week* starts on the day set under *Administration → Settings →
Display* (or the user's language). The stylesheet is only loaded on *My page*.

### For theme authors

The blocks use plain class selectors (`.dashboard-blocks-…`) and a few custom properties
on `:root`, so a theme can restyle them without a specificity fight:
`--dashboard-blocks-border`, `--dashboard-blocks-muted`, `--dashboard-blocks-surface`,
`--dashboard-blocks-accent`, `--dashboard-blocks-alert-bg`, `--dashboard-blocks-alert-text`,
`--dashboard-blocks-success-bg`, `--dashboard-blocks-success-text`.

## Upgrading to 2.0

2.0 removes the blocks *Log time* and *Weekly hours*; they now live in
[Time Autopilot](https://github.com/stbt-de/redmine-time-autopilot) under the same block
names. To keep them:

1. Install Time Autopilot (it needs a database migration), then update Dashboard Blocks.
2. Restart Redmine.

Existing *My page* arrangements, block settings (weekly target, chosen colleague) and
working hours stay as they are – nothing has to be added again. Working hours are now set
under *My account* instead of the block's options. Without Time Autopilot, Redmine simply
skips the two blocks.

## Development

Tests run against a fresh Redmine in a container (Docker required):

```bash
dev/run-tests.sh                        # Redmine 7.0
REDMINE_VERSION=6.1 dev/run-tests.sh    # another version
```

Code comments are written in German.

## Built with AI assistance

This plugin was developed together with an AI coding assistant. Most of the code was
written by the assistant; the direction, design decisions and review came from
[stbt.de](https://stbt.de/). Every feature is covered by integration tests and was
checked in a running Redmine.

## License

MIT, see [`LICENSE`](LICENSE).
