# Material Design Components for Lazarus

Material Design input components for Lazarus / Free Pascal, integrated with the [BGRAControls](https://github.com/bgrabitmap/bgracontrols) package. Licensed as **LGPL v3**.

## Overview

This package provides four Material Design-style input controls that wrap standard LCL widgets, adding:

- **Floating label** — label slides above the field when focused or filled
- **Material underline** — single line at rest, double accent line on focus
- **AccentColor** — customisable colour used for the focused underline and label
- **Consistent API** — all controls expose the same look-and-feel conventions

| Component | Wraps | Use case |
|---|---|---|
| `TBCMaterialEdit` | `TEdit` | Single-line text input |
| `TBCMaterialComboEdit` | `TComboBox` | Drop-down list / editable combo |
| `TBCMaterialCheckComboEdit` | `TCheckListBox` (popup) | Multi-select with checkboxes |
| `TBCMaterialDateEdit` | `TDateEdit` | Date picker with calendar popup |

---

## ⚠️ Conflict warning — BGRAControls users

This package is a **fork** of the Material Design units originally included in [BGRAControls](https://github.com/bgrabitmap/bgracontrols).

If you have **BGRAControls installed**, be aware that:

- BGRAControls already ships a unit named `BCMaterialEdit`. Installing this package alongside BGRAControls will register **duplicate unit names**, causing compiler errors such as `Duplicate identifier` or `Unit already used`.
- The component class names (`TBCMaterialEdit`, etc.) are the same, so both packages **cannot be installed at the same time**.

### Recommended approach

| Scenario | Action |
|---|---|
| You use BGRAControls only for the Material Design components | Remove the Material Design units from your BGRAControls installation (or use this package instead and remove the originals). |
| You use BGRAControls for other controls (BGRASpeedButton, etc.) | Keep BGRAControls installed but **exclude** the conflicting units: in the BGRAControls package editor remove `BCMaterialEdit` from the file list before installing this package. |
| You start a new project | Install only this package — it already depends on `BGRABitmapPack` directly and does not require the full BGRAControls package. |

> **Note:** Downgrading is always safe — you can uninstall this package and go back to the BGRAControls version at any time with no changes to your project's source code, as both expose the same class names and published properties.

---

## Installation in Lazarus IDE

### Prerequisites

The following packages must be installed **before** installing this package:

| Package | Where to get |
|---|---|
| **LCL** | Bundled with Lazarus |
| **BGRABitmapPack** | [github.com/bgrabitmap/bgrabitmap](https://github.com/bgrabitmap/bgrabitmap) |

Install BGRABitmapPack first if it is not yet available in your IDE:

1. Clone or download `bgrabitmap`.
2. In Lazarus: **Package → Open Package File (.lpk)** → select `bgrabitmappack.lpk`.
3. Click **Compile**, then **Use → Install**. Lazarus will rebuild itself.

### Installing this package

1. **Open the package**  
   **Package → Open Package File (.lpk)** → select `materialdesign.lpk` from this repository.

2. **Compile**  
   In the Package Editor window, click **Compile**.  
   All four units (`BCMaterialEdit`, `BCMaterialComboEdit`, `BCMaterialCheckComboEdit`, `BCMaterialDateEdit`) should compile without errors.

3. **Install**  
   Still in the Package Editor, click **Use → Install**.  
   Lazarus will ask to rebuild the IDE — confirm with **Yes**.

4. **Verify**  
   After the IDE restarts, open the **Component Palette** and look for the **Material Design** tab.  
   You should see:
   - `TBCMaterialEdit`
   - `TBCMaterialComboEdit`
   - `TBCMaterialCheckComboEdit`
   - `TBCMaterialDateEdit`

### Adding to a project (without IDE install)

If you prefer not to install into the IDE palette, you can add the package as a dependency of your project:

1. In your project, open **Project → Project Inspector**.
2. Click **Add → New Requirement** and choose `materialdesign`.
3. Add the units you need to the `uses` clause of each form:

```pascal
uses
  BCMaterialEdit,
  BCMaterialComboEdit,
  BCMaterialCheckComboEdit,
  BCMaterialDateEdit;
```

### Uninstalling

1. **Package → Installed Packages** → select `materialdesign` → click **Uninstall**.
2. Confirm the IDE rebuild.

---

## TBCMaterialEdit

Single-line text field with Material Design style.

### Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `Caption` | `TCaption` | `''` | Floating label text |
| `Text` | `TCaption` | `''` | Current text value |
| `TextHint` | `TTranslateString` | `''` | Placeholder shown when empty |
| `AccentColor` | `TColor` | — | Colour of focused underline and label |
| `DisabledColor` | `TColor` | — | Underline colour when disabled |
| `ShowClearButton` | `Boolean` | `False` | Shows a `×` button when the field has text |
| `ReadOnly` | `Boolean` | `False` | Prevents user edits |
| `MaxLength` | `Integer` | `0` | Max characters (0 = unlimited) |
| `EchoMode` | `TEchoMode` | `emNormal` | Use `emPassword` for password fields |
| `PasswordChar` | `Char` | `#0` | Mask character for password mode |
| `CharCase` | `TEditCharCase` | `ecNormal` | Force upper/lower case |
| `NumbersOnly` | `Boolean` | `False` | Accept only numeric input |
| `AutoSelect` | `Boolean` | `True` | Select all on focus |
| `LabelSpacing` | `Integer` | `4` | Pixels between label and field |
| `EditLabel` | `TBoundLabel` | — | Direct access to the internal label |
| `ClearButton` | `TButton` | — | Direct access to the clear button (read-only) |

### Key Events

`OnChange`, `OnClick`, `OnEnter`, `OnExit`, `OnKeyDown`, `OnKeyPress`, `OnKeyUp`, `OnClearButtonClick`, `OnEditingDone`, `OnUTF8KeyPress`

### Example

```pascal
BCMaterialEdit1.Caption    := 'E-mail';
BCMaterialEdit1.TextHint   := 'user@example.com';
BCMaterialEdit1.AccentColor := RGBToColor(33, 150, 243);
BCMaterialEdit1.ShowClearButton := True;
```

---

## TBCMaterialComboEdit

Drop-down selector with Material Design style. Equivalent to an HTML `<select>`.

### Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `Caption` | `TCaption` | `''` | Floating label text |
| `Text` | `TCaption` | `''` | Currently displayed text |
| `Items` | `TStrings` | — | List of options |
| `ItemIndex` | `Integer` | `-1` | Index of the selected item |
| `Style` | `TComboBoxStyle` | `csDropDown` | `csDropDown` (editable) or `csDropDownList` (read-only) |
| `AccentColor` | `TColor` | — | Focused underline and label colour |
| `DisabledColor` | `TColor` | — | Underline colour when disabled |
| `Sorted` | `Boolean` | `False` | Sort items alphabetically |
| `AutoComplete` | `Boolean` | `True` | Enable auto-complete while typing |
| `DropDownCount` | `Integer` | — | Number of visible rows in the drop-down |
| `MaxLength` | `Integer` | `0` | Max characters for editable style |
| `ReadOnly` | `Boolean` | `False` | Disable editing in `csDropDown` mode |
| `LabelSpacing` | `Integer` | `4` | Pixels between label and field |

### Key Events

`OnChange`, `OnEnter`, `OnExit`, `OnKeyDown`, `OnKeyPress`, `OnKeyUp`, `OnEditingDone`

### Example

```pascal
BCMaterialComboEdit1.Caption := 'Country';
BCMaterialComboEdit1.Items.CommaText := 'Brazil,Argentina,Chile';
BCMaterialComboEdit1.Style := csDropDownList;
BCMaterialComboEdit1.AccentColor := RGBToColor(76, 175, 80);
```

---

## TBCMaterialCheckComboEdit

Multi-select field that opens a floating panel containing a `TCheckListBox`. Equivalent to `<select multiple>`.

### Display formats (`TCheckComboDisplayFormat`)

| Value | Displayed text example |
|---|---|
| `cdfCommaSeparated` | `"Item1, Item2, Item3"` |
| `cdfCountOnly` | `"3 selected"` |
| `cdfCountAndFirst` | `"Item1 (+2)"` |

### Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `Caption` | `TCaption` | `''` | Floating label text |
| `Items` | `TStrings` | — | List of options |
| `Checked[i]` | `Boolean` | — | Checked state of item `i` |
| `CheckedCount` | `Integer` | — | Number of checked items (read-only) |
| `DisplayFormat` | `TCheckComboDisplayFormat` | `cdfCommaSeparated` | How selected items are shown |
| `EmptyText` | `string` | `''` | Text shown when nothing is selected |
| `AccentColor` | `TColor` | — | Focused underline and label colour |
| `DisabledColor` | `TColor` | — | Underline colour when disabled |
| `DropDownCount` | `Integer` | — | Max visible rows in the floating list |
| `Sorted` | `Boolean` | `False` | Sort items alphabetically |
| `LabelSpacing` | `Integer` | `4` | Pixels between label and field |

### Key Events

| Event | Description |
|---|---|
| `OnCheckChange(Sender, AIndex, AChecked)` | Fires when any checkbox changes |
| `OnDropDownOpen` | Fires when the floating panel opens |
| `OnDropDownClose` | Fires when the floating panel closes |

The panel closes automatically when the user clicks outside it, or presses **Escape** or **Enter**.

### Example

```pascal
BCMaterialCheckComboEdit1.Caption := 'Permissions';
BCMaterialCheckComboEdit1.Items.CommaText := 'Read,Write,Execute';
BCMaterialCheckComboEdit1.DisplayFormat := cdfCountAndFirst;
BCMaterialCheckComboEdit1.EmptyText := '(none selected)';
BCMaterialCheckComboEdit1.Checked[0] := True;
```

---

## TBCMaterialDateEdit

Date picker with floating label and Material Design underline. Wraps the LCL `TDateEdit`.

### Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `Caption` | `TCaption` | `''` | Floating label text |
| `Date` | `TDateTime` | — | Selected date value |
| `Text` | `TCaption` | — | Date as formatted string |
| `TextHint` | `TTranslateString` | `''` | Placeholder shown when empty |
| `DateOrder` | `TDateOrder` | `doNone` | Display order: `doDMY`, `doMDY`, `doYMD`, `doNone` |
| `DirectInput` | `Boolean` | `True` | Allow typing a date; `False` = calendar only |
| `CalendarDisplaySettings` | `TDisplaySettings` | — | Controls visible calendar elements |
| `AccentColor` | `TColor` | — | Focused underline and label colour |
| `DisabledColor` | `TColor` | — | Underline colour when disabled |
| `ShowClearButton` | `Boolean` | `False` | Shows a `×` button to clear the date |
| `ReadOnly` | `Boolean` | `False` | Prevents user edits |
| `LabelSpacing` | `Integer` | `4` | Pixels between label and field |
| `EditLabel` | `TBoundLabel` | — | Direct access to the internal label |
| `DateEdit` | `TDateEdit` | — | Direct access to the internal `TDateEdit` |
| `ClearButton` | `TButton` | — | Direct access to the clear button (read-only) |

### Methods

| Method | Description |
|---|---|
| `ClearDate` | Clears the selected date |

### Key Events

`OnChange`, `OnClick`, `OnEnter`, `OnExit`, `OnKeyDown`, `OnKeyPress`, `OnKeyUp`, `OnAcceptDate`, `OnCustomDate`, `OnClearButtonClick`, `OnEditingDone`, `OnUTF8KeyPress`

### Example

```pascal
BCMaterialDateEdit1.Caption    := 'Birth date';
BCMaterialDateEdit1.DateOrder  := doDMY;
BCMaterialDateEdit1.DirectInput := False;
BCMaterialDateEdit1.AccentColor := RGBToColor(156, 39, 176);
BCMaterialDateEdit1.ShowClearButton := True;
```

---

## Common Behaviour

All four controls share the same visual conventions:

- **At rest**: thin grey underline beneath the field.
- **On focus**: underline thickens and changes to `AccentColor`; the floating label animates to the top in `AccentColor`.
- **Disabled**: underline uses `DisabledColor`.
- Base class `TBCMaterialEditBase<T>` is generic; `T` is the wrapped LCL control.

---

## License

LGPL v3 — same as [BGRAControls](https://github.com/bgrabitmap/bgracontrols).
var
MDBUTTONBALLOTBOX: string = '✗';
MDBUTTONBALLOTBOXWITHCHECK: string = '✓';
MDBUTTONRADIOBUTTON: string = '🔘';
MDBUTTONRADIOBUTTONCIRCLE: string = '◯';
```
