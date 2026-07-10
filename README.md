<p align="center">
  <img src="docs/assets/topoff-icon-transparent.png" alt="TopOff app icon" width="112">
</p>

<h1 align="center">TopOff</h1>

<p align="center">
  A lightweight macOS menu bar app for checking and updating Homebrew packages.
</p>

<p align="center">
  Free · MIT licensed · No telemetry · macOS 14+
</p>

## What It Does

TopOff runs Homebrew from the menu bar so you can check outdated formulae and casks, update everything, or update individual packages without keeping Terminal open.

## Features

- **Menu bar update list** — Shows outdated packages with version changes.
- **After-unlock checks** — Default check mode. TopOff checks shortly after unlock when the minimum check interval has passed.
- **Periodic checks** — Optional check mode with 1 hour, 4 hour, 12 hour, or 24 hour intervals.
- **Update notifications** — Sends a notification only when updates exist, with an **Update All** action. The menu shows the package names.
- **One-click upgrades** — Run normal `brew upgrade` or greedy upgrades for auto-updating casks.
- **Selective updates and skips** — Update or skip individual packages, with optional remembered skips.
- **Progress and history** — Shows the current update progress and the most recent upgraded packages.
- **Auto cleanup** — Optionally runs `brew cleanup` after successful updates, with a deep-prune option.
- **Admin retry** — Prompts for an administrator password when Homebrew reports a permission failure.
- **Clearer failure handling** — Keeps partial successful upgrades reflected in the menu and shows specific messages for common cask conflicts, such as an existing app blocking upgrade.

## Installation

### Build From Source

1. Clone this repository.
2. Open `TopOff/TopOff.xcodeproj` in Xcode.
3. Select the `TopOff` scheme.
4. Build and run with `Cmd+R`.

### Requirements

- macOS 14.0 or later
- [Homebrew](https://brew.sh)

## Usage

1. Click the TopOff menu bar icon.
2. Choose **Check Updates** to refresh the list.
3. Choose **Update All** or update a single package.
4. Open the menu during an update to see progress.

## Check Modes

TopOff supports one automatic Homebrew check mode at a time:

| Mode | Behavior |
|------|----------|
| After Unlock | Default. Checks after unlock when enough time has passed since the last check. |
| Periodic | Checks on the selected interval while TopOff is running. |

## Greedy Updates

Some casks, such as browsers or chat apps, have their own auto-updaters and are normally skipped by Homebrew. Greedy mode includes them.

| Action | Command |
|--------|---------|
| Update All | `brew upgrade` |
| Update All (Greedy Mode on) | `brew upgrade`, then `brew upgrade --greedy` |

When **Greedy Mode** is enabled, checks use `brew outdated --greedy` and the update button changes to **Update All (Greedy)**.

## Notes

- TopOff does not auto-fix cask conflicts by force-reinstalling apps. If Homebrew reports an existing app conflict, TopOff shows the path so you can decide whether to move, remove, or reinstall it.
- Homebrew network activity may appear under TopOff in firewall tools because TopOff runs `brew` as a child process.
- TopOff checks GitHub for app updates, but does not include analytics or telemetry.

## Attribution

This fork builds on the original TopOff project by Thomas Haslam. TopOff is released under the MIT License.
