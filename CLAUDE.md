# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository is a macOS ZFS Desktop Attached Storage (DAS) solution consisting of:
- **Shell scripts** (`scripts/`) — 17 scripts for ZFS pool creation, encryption, auto-mount, monitoring, Time Machine setup, and maintenance
- **SwiftBar plugins** (`swiftbar/`) — macOS menu bar monitoring plugins
- **Website** (`website/`) — React/Vite marketing and documentation site

## Website Development Commands

All commands run from the `website/` directory:

```bash
npm run dev      # Start dev server at http://localhost:3000 (auto-opens browser)
npm run build    # Production build to dist/
npm run preview  # Preview production build
```

There are no test commands — this project has no test suite for the frontend.

## Website Architecture

**Stack:** React 18, Vite, React Router v6, Tailwind CSS, Heroicons, PrismJS

**Routing** (`App.jsx`):
- `/` → Home
- `/getting-started` → GettingStarted
- `/wizards/*` → Wizards hub (3 interactive setup wizards)
- `/docs/*` → Documentation viewer
- `/download` → Download page

**Key architectural patterns:**
- Wizards (`components/wizards/`) are multi-step components that generate customized shell commands. Each wizard manages its own local state via `useState`. They share `WizardContainer`, `CommandBlock` (copy-to-clipboard code blocks), and `StepIndicator`.
- Analytics are centralized in `src/utils/analytics.js` with typed GA4 event tracking. All user interactions (wizard steps, copies, downloads, form submissions) are tracked through this utility.
- Tailwind uses a custom palette: `primary` (blue) and `accent` (teal), with custom animations (`fade-in`, `slide-up`, `pulse-slow`) defined in `tailwind.config.js`.
- No global state management — all state is local to components.

## Shell Scripts

Scripts target macOS with OpenZFS. They require Homebrew-installed ZFS (`brew install openzfs`). Key scripts:
- `create-pool.sh` — ZFS pool creation with RAID-Z1
- `setup-encryption.sh` — AES-256 encryption
- `zfs-automount.sh` — LaunchDaemon auto-mount on boot
- `setup-timemachine.sh` — Time Machine integration
- `setup-monitoring.sh` — SwiftBar plugin installation

Shell scripts are linted with ShellCheck (`.shellcheckrc` at repo root).
