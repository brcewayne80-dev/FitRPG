# Mobile Health App — Core Vision (Phase 1)

**Purpose:** A mobile-first health & fitness app that converts real-world health metrics and daily habits into **experience points (XP)** users can spend/earn in connected mini-games. The app is **offline-first**, **privacy-first**, and lays the **foundation for future expansion** (e.g., companion mini-PC dashboard).

## What “success” looks like (Phase 1)
- Users see clear **XP totals** and **available XP** at a glance.
- Users can track **objectives** and see recent completions.
- The app runs **entirely local** (no account required); data is stored on-device.
- A minimal **immutable XP ledger** records XP events (append-only).
- The app provides clear entry points: **Play Now**, **Objectives**, **Stats**, **Settings**.

## Non-goals for Phase 1
- No cloud sync or accounts (will come later).
- No AI coaching yet.
- Only basic/minimal mini-game hooks.

## Guiding principles
- **Privacy & Ownership:** on-device first; encrypted local storage later in Phase 1.
- **Simplicity:** smallest set of features to validate the loop (real world → XP → game).
- **Extensibility:** scene structure and data formats designed to grow without rewrites.

## Interfaces we plan to support (later steps)
- Apple HealthKit / Google Fit ingestion (daily metrics like steps, HR, activity minutes, sleep, weight).
- Configurable XP multipliers (e.g., 10 min of exercise → 50 XP).
- Append-only XP ledger with `pending` vs `confirmed` entries.
