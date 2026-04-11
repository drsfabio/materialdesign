# Changelog

All notable changes to **FRComponents** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.0.0] — 2026-04-11

### Package rename
- **Renamed package** from `materialdesign` to **`frcomponents`**. This is a
  fork of the original `materialdesign` package by the bgrabitmap team,
  with substantial hardening, new components and quality infrastructure.
- Main unit renamed: `materialdesign.pas` → `frcomponents.pas`.
- Package file: `materialdesign.lpk` → `frcomponents.lpk`.
- **Migration:** consumers should update their `.lpi` / `.lpr` to reference
  `frcomponents` instead of `materialdesign`. The unit names of individual
  components (e.g. `FRMaterial3Button`, `FRMaterialEdit`) are UNCHANGED, so
  `uses` clauses inside forms do not need to change.

### Added — new components

- **`TFRMaterialTitleBar`** in `FRMaterial3TitleBar.pas` — custom MD3 title
  bar for borderless forms, with NavIcon, Actions collection (badges,
  separators), DWM shadow and Window control buttons.
- **`TFRMaterialGridPanel`** in `FRMaterial3GridPanel.pas` — 12-column
  auto-flow grid layout with:
  - `AutoColSpan: Boolean` — when `True`, child controls' column span is
    resolved automatically from their `TFRFieldSize` property.
  - `ColumnCount` (default 12), `GapH` (default 20), `GapV` (default 16).
  - Design-time guide lines to visualize columns.
- **`TFRFieldSize` enum** — new semantic size token (`fsAuto`, `fsTiny`,
  `fsSmall`, `fsMedium`, `fsLarge`, `fsHuge`, `fsFull`) on every
  `TFRMaterial3Control`, used by `TFRMaterialGridPanel` for responsive
  layouts without hard-coded column spans.

### Added — VirtualDataGrid v2 rework

`TFRMaterialVirtualDataGrid` received a complete visual rework while
preserving its public API:

- **Header auto-height** — automatically sized based on the tallest
  word-wrapped column caption. No more truncated captions like "DDE
  MÁXIMO". Recalculated on column resize.
- **Spring area fix** — the empty area to the right of the last column is
  now painted with `SurfaceContainerHighest` + bottom divider. No more
  black artifact.
- **Empty state** — new `EmptyText` and `EmptyHint` properties. When the
  grid has no nodes, a centered icon + message is drawn via `DoAfterPaint`.
- **Loading state** — new `Loading: Boolean` property. Toggles a
  semi-transparent overlay with an animated 8-dot MD3 spinner and a
  `LoadingText` message. Timer-driven (16ms) with proper lifecycle
  cleanup in `BeforeDestruction`.
- **Refined row states** — three-pass rendering for combined states:
  `baseBg → state layer → editable hint`. Handles hover-on-selection,
  focus-on-hover, and selection + editable cell correctly per MD3 spec.

### Added — Quality infrastructure

- **Smoke test runner** (`tests/smoke_runner.lpi` + `.lpr`) — standalone
  console program that creates every public MD3 component on a hidden
  form, parents it, destroys it, and runs a 20-iteration theme stress
  test cycling dark/light × density × variant. Exits 0 if all 40 tests
  pass. Intended for CI.
- **Convention block comment** at the top of `FRMaterial3Base.pas`
  documenting the lifecycle invariants every component must follow.

### Changed — Core hardening

- **Canonical lifecycle helpers** added to `FRMaterial3Base.pas`:
  - `FRMDCanPaint(AControl): Boolean` — single-source check for
    `csDestroying`/`csLoading`/dimensions/handle/parent before painting.
  - `FRMDSafeInvalidate(AControl)` — schedule repaint only when safe.
    Checks the same flags plus `HandleAllocated` / `Parent <> nil`.
  - `FRMDIsDestroying(AComponent): Boolean` — inline guard for callbacks
    and timers.
- **`BeforeDestruction` pattern** — `TFRMaterial3Control` and
  `TFRMaterial3Graphic` now unregister from the theme manager and stop
  ripple/loading timers in `BeforeDestruction`, BEFORE the owner chain
  cascade. Subclasses (Edit, SearchEdit, SpinEdit, CheckComboEdit,
  VirtualDataGrid, AlterarTemplate-style forms) override to nil their
  own event handlers early.
- **`Loaded()` override in base classes** replaces the dangerous
  push-in-`RegisterComponent` approach. The initial theme is applied
  in `Loaded()` which runs AFTER LFM streaming, when all sub-components
  and properties are fully populated — safe for virtual dispatch.
- **Paint guards (`FRMDCanPaint`)** added to **all 17 overridden `Paint`
  methods** in the library (AppBar, Toggle, Slider, MaskEdit, TimePicker,
  TreeView, ComboEdit, CurrencyEdit, DateEdit, MemoEdit, Edit, SpinEdit,
  SearchEdit, CheckComboEdit, VirtualDataGrid, Control, Graphic).
  Descendants that call `inherited Paint` then access sub-components
  are now fully guarded.
- **`ThemeManager.ApplyTheme` hardening:**
  - Recursion guard (`FApplying`) prevents infinite loops when a
    listener's `ApplyTheme` mutates manager state.
  - `try/except` per listener — one broken listener cannot bring down
    the whole theme propagation.
  - Nil pointer check before casting in iterator.
  - **Removed** the previous push-in-`RegisterComponent` that caused
    access violations with derived classes whose sub-components were
    not yet constructed.
- **`FreeAndNil` sweep** — all ~20 destructors that freed fields now
  use `FreeAndNil(FField)` instead of `FField.Free`. Eliminates an
  entire class of dangling-pointer bugs.
- **`FRMDSafeInvalidate` sweep** — ~89 sites across 18 files where
  setters called raw `Invalidate` now call `FRMDSafeInvalidate(Self)`.
- **Notification handler guards** — `TFRMaterialNavBar`,
  `TFRMaterialNavDrawer`, `TFRMaterialNavRail` check `Assigned(FItems)`
  before iterating, since `FItems` may have been `FreeAndNil`ed in
  `Destroy` before the owner chain fires `Notification(opRemove)`.

### Fixed — Critical bugs exposed by the smoke runner

- **Snackbar race** in `DoAnimTick`: `FPanel.Free` was called without
  disabling click events first. A queued `WM_LBUTTONDOWN` arriving after
  the free would AV. Now disables and hides before free.
- **VirtualDataGrid `FFilterTexts` init order** — `TDictionary` was
  created AFTER `inherited Create`, so if any virtual method fired during
  `inherited Create` and touched `FFilterTexts`, the destructor would
  later try to free uninitialized memory. Moved before `inherited`.
- **CheckComboEdit / SpinEdit / SearchEdit** `Paint` overrides touched
  sub-controls (`FDisplayEdit`, `FMinusButton`, `FSearchButton`) without
  nil guards. Paint firing during construction or destruction caused
  AVs. All guarded now.
- **FRMaterialEditBase sub-button handlers** — `OnClick` on the 5
  internal icon buttons (Clear, Search, Leading, Eye, Copy) and
  `OnChange` on the inner `FEdit` are now nilled in `BeforeDestruction`,
  so queued events cannot fire on a half-destroyed edit.

### Grid defaults

- `TFRMaterialGridPanel` default `GapH` raised from 16 to **20**, and
  `GapV` from 8 to **16**, providing more breathing room with
  Standard/Filled variants under compact density. Existing forms that
  explicitly set smaller gaps in the LFM are unaffected.

### Documentation

- `LICENSE` file added with full LGPL v3 + linking exception text and
  third-party attributions.
- `CHANGELOG.md` added (this file).
- `README.md` updated with the new package name, installation steps
  and credits to the upstream `materialdesign` project.

---

## [1.x] — Previous releases

Previous releases were published under the name `materialdesign` by the
bgrabitmap team. See https://github.com/bgrabitmap/materialdesign for
upstream history.
