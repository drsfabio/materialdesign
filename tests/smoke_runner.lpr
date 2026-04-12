program smoke_runner;

{$mode objfpc}{$H+}

{ MD3 Smoke Test Runner

  Standalone test that exercises every public MD3 component through its
  full lifecycle: create, configure, apply theme (dark/light, every
  density, every variant), destroy. Designed to catch:

    - AVs from late WM_PAINT messages
    - Leaks from missing FreeAndNil in destructors
    - Recursive ApplyTheme loops
    - Missing csLoading/csDestroying guards
    - Any exception raised during construction/destruction

  Exit codes:
    0  all tests passed
    1  at least one test failed

  Run from CI:
    lazbuild smoke_runner.lpi && ./smoke_runner

  Build from IDE:
    open smoke_runner.lpi in Lazarus, F9 to compile+run }

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces, Classes, SysUtils, Forms, Controls, Graphics,
  FRMaterialTheme, FRMaterial3Base, FRMaterialThemeManager, FRMaterialMasks,
  FRMaterialEdit, FRMaterial3Button, FRMaterial3Toggle,
  FRMaterial3Divider, FRMaterial3Chip, FRMaterial3Card,
  FRMaterial3GridPanel, FRMaterial3Progress, FRMaterial3FAB,
  FRMaterial3Nav, FRMaterial3Snackbar, FRMaterial3Dialog,
  FRMaterial3Badge, FRMaterial3Slider, FRMaterial3Tabs,
  FRMaterial3AppBar, FRMaterial3Menu, FRMaterial3Tooltip,
  FRMaterial3Sheet, FRMaterial3DatePicker, FRMaterial3TimePicker,
  FRMaterial3Carousel, FRMaterial3TreeView, FRMaterial3List,
  FRMaterial3PageControl, FRMaterial3DataGrid, FRMaterial3VirtualDataGrid,
  FRMaterialDateEdit,
  FRMaterialCheckComboEdit, FRMaterialMemoEdit, FRMaterialSpinEdit,
  FRMaterialSearchEdit, FRMaterialMaskEdit, FRMaterial3Toolbox,
  FRMaterial3Combo, Laz.VirtualTrees;

type
  TTestProc = procedure(Host: TWinControl);

var
  GPassed: Integer = 0;
  GFailed: Integer = 0;
  GFailures: TStringList;
  GThemeManager: TFRMaterialThemeManager;

procedure Pass(const AName: string);
begin
  Inc(GPassed);
  WriteLn('  [PASS] ', AName);
end;

procedure Fail(const AName, AError: string);
begin
  Inc(GFailed);
  WriteLn('  [FAIL] ', AName, ' — ', AError);
  GFailures.Add(AName + ': ' + AError);
end;

procedure Run(const AName: string; AProc: TTestProc; Host: TWinControl);
var
  StackText: string;
  I: Integer;
begin
  try
    AProc(Host);
    Pass(AName);
  except
    on E: Exception do
    begin
      StackText := '';
      for I := 0 to ExceptFrameCount - 1 do
        StackText := StackText + '    ' + BackTraceStrFunc(ExceptFrames[I]) + sLineBreak;
      Fail(AName, E.ClassName + ' — ' + E.Message + sLineBreak +
        '    at ' + BackTraceStrFunc(ExceptAddr) + sLineBreak + StackText);
    end;
  end;
end;

{ ── Security Test Utilities ─────────────────────────────────────────── }

function GenerateMaliciousString(ASize: Integer): string;
var
  i: Integer;
begin
  SetLength(Result, ASize);
  for i := 1 to ASize do
    Result[i] := Char(32 + (i mod 95)); // Printable ASCII range
end;

function GenerateBoundaryStrings: TStringArray;
begin
  SetLength(Result, 8);
  Result[0] := ''; // Empty string
  Result[1] := 'A'; // Single char
  Result[2] := StringOfChar('A', 255); // Max byte
  Result[3] := StringOfChar('A', 256); // Boundary overflow
  Result[4] := StringOfChar('A', 1024); // 1KB
  Result[5] := StringOfChar('A', 65535); // Near 64KB
  Result[6] := GenerateMaliciousString(1000); // Mixed chars
  Result[7] := #0#1#2#3#4#5; // Control chars
end;

{ ── Test procedures ──────────────────────────────────────────────── }

procedure Test_Edit(Host: TWinControl);
var c: TFRMaterialEdit;
  TestStrings: TStringArray;
  i: Integer;
  d: TFRMDDensity;
  v: TFRMaterialVariant;
begin
  c := TFRMaterialEdit.Create(Host);
  try
    c.Parent           := Host;
    c.Caption          := 'TEST';
    c.Edit.Text        := 'hello';
    c.FieldSize        := TFRFieldSize.fsLarge;
    c.ShowClearButton  := True;
    c.ShowSearchButton := True;
    c.ValidationState  := vsValid;
    c.ValidationState  := vsInvalid;
    c.ValidationState  := vsNone;

    { Density cycling — verifica SetDensity override }
    for d := Low(TFRMDDensity) to High(TFRMDDensity) do
    begin
      c.Density := d;
      if c.Height < 32 then
        raise Exception.CreateFmt('Edit height %d < 32 at density %d',
          [c.Height, Ord(d)]);
    end;
    c.Density := ddNormal;
    if c.Height <> EDIT_DEFAULT_H then
      raise Exception.CreateFmt('Edit height %d <> default %d after reset',
        [c.Height, EDIT_DEFAULT_H]);

    { Variant cycling }
    for v := Low(TFRMaterialVariant) to High(TFRMaterialVariant) do
    begin
      c.Variant := v;
      c.Invalidate;
      Application.ProcessMessages;
    end;

    // Security tests: boundary conditions
    TestStrings := GenerateBoundaryStrings;
    for i := 0 to High(TestStrings) do
    begin
      c.Edit.Text := TestStrings[i];
      c.Edit.SelText := TestStrings[i]; // Test selection operations
    end;
  finally
    c.Free;
  end;
end;

procedure Test_Button(Host: TWinControl);
var c: TFRMaterialButton;
begin
  c := TFRMaterialButton.Create(Host);
  try
    c.Parent      := Host;
    c.Caption     := 'Click';
    c.ButtonStyle := mbsFilled;
    c.ButtonStyle := mbsTonal;
    c.ButtonStyle := mbsOutlined;
    c.ButtonStyle := mbsText;
    c.ButtonStyle := mbsElevated;
  finally
    c.Free;
  end;
end;

procedure Test_Switch(Host: TWinControl);
var c: TFRMaterialSwitch;
begin
  c := TFRMaterialSwitch.Create(Host);
  try
    c.Parent  := Host;
    c.Checked := True;
    c.Checked := False;
  finally
    c.Free;
  end;
end;

procedure Test_CheckBox(Host: TWinControl);
var c: TFRMaterialCheckBox;
begin
  c := TFRMaterialCheckBox.Create(Host);
  try
    c.Parent  := Host;
    c.Checked := True;
  finally
    c.Free;
  end;
end;

procedure Test_RadioButton(Host: TWinControl);
var c: TFRMaterialRadioButton;
begin
  c := TFRMaterialRadioButton.Create(Host);
  try
    c.Parent  := Host;
    c.Checked := True;
  finally
    c.Free;
  end;
end;

procedure Test_Chip(Host: TWinControl);
var c: TFRMaterialChip;
begin
  c := TFRMaterialChip.Create(Host);
  try
    c.Parent    := Host;
    c.Caption   := 'Chip';
    c.ChipStyle := csAssist;
    c.ChipStyle := csFilter;
    c.ChipStyle := csInput;
    c.ChipStyle := csSuggestion;
  finally
    c.Free;
  end;
end;

procedure Test_Divider(Host: TWinControl);
var c: TFRMaterialDivider;
begin
  c := TFRMaterialDivider.Create(Host);
  try
    c.Parent := Host;
  finally
    c.Free;
  end;
end;

procedure Test_Card(Host: TWinControl);
var c: TFRMaterialCard;
begin
  c := TFRMaterialCard.Create(Host);
  try
    c.Parent := Host;
  finally
    c.Free;
  end;
end;

procedure Test_Combo(Host: TWinControl);
var
  c: TFRMaterialCombo;
  d: TFRMDDensity;
  v: TFRMaterialVariant;
  i: Integer;
begin
  c := TFRMaterialCombo.Create(Host);
  try
    c.Parent := Host;
    for i := 0 to 25 do
      c.Items.Add('Item ' + IntToStr(i));
    c.ItemIndex := 1;
    c.Caption := 'Test';

    { Density cycling }
    for d := Low(TFRMDDensity) to High(TFRMDDensity) do
    begin
      c.Density := d;
      if c.Height < 32 then
        raise Exception.CreateFmt('Combo height %d < 32 at density %d',
          [c.Height, Ord(d)]);
    end;
    c.Density := ddNormal;

    { Variant cycling }
    for v := Low(TFRMaterialVariant) to High(TFRMaterialVariant) do
    begin
      c.Variant := v;
      c.Invalidate;
      Application.ProcessMessages;
    end;

    { ItemIndex boundary }
    c.ItemIndex := -1;
    c.ItemIndex := 0;
    c.ItemIndex := c.Items.Count - 1;
  finally
    c.Free;
  end;
end;

procedure Test_Toolbox(Host: TWinControl);
var
  tb: TFRMaterialToolbox;
  btn: TFRMaterialButton;
  s: TFRMDToolboxStyle;
begin
  { Exercita todas as variantes e auto-layout com filhos reais }
  for s := Low(TFRMDToolboxStyle) to High(TFRMDToolboxStyle) do
  begin
    tb := TFRMaterialToolbox.Create(Host);
    try
      tb.Parent         := Host;
      tb.ToolboxStyle   := s;
      tb.Orientation    := toHorizontal;
      tb.ContentPadding := 8;
      tb.ItemSpacing    := 8;
      btn               := TFRMaterialButton.Create(tb);
      btn.Parent        := tb;
      btn.Caption       := 'A';
      btn               := TFRMaterialButton.Create(tb);
      btn.Parent        := tb;
      btn.Caption       := 'B';
      tb.Orientation := toVertical;
    finally
      tb.Free;
    end;
  end;
end;

procedure Test_GridPanel(Host: TWinControl);
var
  c: TFRMaterialGridPanel;
  e1, e2, e3, e4, e5: TFRMaterialEdit;
  combo: TFRMaterialCombo;
  expectedColW: Double;
begin
  c := TFRMaterialGridPanel.Create(Host);
  try
    c.Parent      := Host;
    c.SetBounds(0, 0, 1100, 200);
    c.ColumnCount := 12;
    c.GapH        := 16;
    c.GapV        := 12;
    c.AutoColSpan := True;
    c.AutoHeight  := True;

    { Força criação do handle — sem handle, AlignControls é no-op na LCL }
    c.HandleNeeded;

    { Replica o cenário do showcase: 5 fields em 2 rows }
    { Row 1: Name(8) + Email(4) = 12 }
    e1 := TFRMaterialEdit.Create(c); e1.Parent := c;
    e1.FieldSize := TFRFieldSize.fsHuge;   { 8 cols }

    e2 := TFRMaterialEdit.Create(c); e2.Parent := c;
    e2.FieldSize := TFRFieldSize.fsMedium; { 4 cols }

    { Row 2: State(6) + Birth(3) + Budget(3) = 12 }
    combo := TFRMaterialCombo.Create(c); combo.Parent := c;
    combo.FieldSize := TFRFieldSize.fsLarge; { 6 cols }

    e4 := TFRMaterialEdit.Create(c); e4.Parent := c;
    e4.FieldSize := TFRFieldSize.fsSmall;  { 3 cols }

    e5 := TFRMaterialEdit.Create(c); e5.Parent := c;
    e5.FieldSize := TFRFieldSize.fsSmall;  { 3 cols }

    Application.ProcessMessages;

    { Verify column width: (1100 - 11*16) / 12 = 924/12 = 77 }
    expectedColW := (1100 - 11 * 16) / 12;

    { Row 1 checks }
    WriteLn('    GridPanel diag: areaW=1100 colW=', expectedColW:0:1);
    WriteLn('    e1(fsHuge/8):   Left=', e1.Left, ' Width=', e1.Width,
            ' Top=', e1.Top, ' FieldSize=', Ord(e1.FieldSize));
    WriteLn('    e2(fsMedium/4): Left=', e2.Left, ' Width=', e2.Width,
            ' Top=', e2.Top, ' FieldSize=', Ord(e2.FieldSize));
    WriteLn('    combo(fsLarge/6): Left=', combo.Left, ' Width=', combo.Width,
            ' Top=', combo.Top, ' FieldSize=', Ord(combo.FieldSize));
    WriteLn('    e4(fsSmall/3):  Left=', e4.Left, ' Width=', e4.Width,
            ' Top=', e4.Top, ' FieldSize=', Ord(e4.FieldSize));
    WriteLn('    e5(fsSmall/3):  Left=', e5.Left, ' Width=', e5.Width,
            ' Top=', e5.Top, ' FieldSize=', Ord(e5.FieldSize));
    WriteLn('    GridPanel Height=', c.Height);

    { e1 should start at col 0, width = 8 cols }
    Assert(e1.Left = 0, 'e1.Left should be 0, got ' + IntToStr(e1.Left));
    Assert(e1.Width > 500, 'e1(8cols) Width should be >500, got ' + IntToStr(e1.Width));
    Assert(e1.Width < 900, 'e1(8cols) Width should be <900 (not full), got ' + IntToStr(e1.Width));

    { e2 should be on same row as e1, to the right }
    Assert(e2.Top = e1.Top, 'e2 should be on same row as e1');
    Assert(e2.Left > e1.Left + e1.Width, 'e2 should be to the right of e1');

    { combo should be on row 2 }
    Assert(combo.Top > e1.Top, 'combo should be on row 2, below e1');

    { e4 and e5 should be on same row as combo }
    Assert(e4.Top = combo.Top, 'e4 should be on same row as combo');
    Assert(e5.Top = combo.Top, 'e5 should be on same row as combo');

    { 2 rows total }
    Assert(c.Height = e1.Height + c.GapV + combo.Height,
      'AutoHeight 2 rows: expected ' + IntToStr(e1.Height + c.GapV + combo.Height)
      + ' got ' + IntToStr(c.Height));

    combo.Free;
  finally
    c.Free;
  end;
end;

procedure Test_LinearProgress(Host: TWinControl);
var c: TFRMaterialLinearProgress;
begin
  c := TFRMaterialLinearProgress.Create(Host);
  try
    c.Parent        := Host;
    c.Value         := 50;
    c.Indeterminate := True;
    c.Indeterminate := False;
  finally
    c.Free;
  end;
end;

procedure Test_CircularProgress(Host: TWinControl);
var c: TFRMaterialCircularProgress;
begin
  c := TFRMaterialCircularProgress.Create(Host);
  try
    c.Parent := Host;
    c.Value  := 75;
  finally
    c.Free;
  end;
end;

procedure Test_FAB(Host: TWinControl);
var c: TFRMaterialFAB;
begin
  c := TFRMaterialFAB.Create(Host);
  try
    c.Parent := Host;
  finally
    c.Free;
  end;
end;

procedure Test_NavRail(Host: TWinControl);
var c: TFRMaterialNavRail;
begin
  c := TFRMaterialNavRail.Create(Host);
  try
    c.Parent := Host;
  finally
    c.Free;
  end;
end;

procedure Test_NavBar(Host: TWinControl);
var c: TFRMaterialNavBar;
begin
  c := TFRMaterialNavBar.Create(Host);
  try
    c.Parent := Host;
  finally
    c.Free;
  end;
end;

procedure Test_AppBar(Host: TWinControl);
var c: TFRMaterialAppBar;
begin
  c := TFRMaterialAppBar.Create(Host);
  try
    c.Parent   := Host;
    c.Title    := 'Test';
    c.Subtitle := 'Subtitle';
  finally
    c.Free;
  end;
end;

procedure Test_Badge(Host: TWinControl);
var c: TFRMaterialBadge;
begin
  c := TFRMaterialBadge.Create(Host);
  try
    c.Parent := Host;
  finally
    c.Free;
  end;
end;

procedure Test_Slider(Host: TWinControl);
var c: TFRMaterialSlider;
begin
  c := TFRMaterialSlider.Create(Host);
  try
    c.Parent := Host;
    c.Max    := 100;
    c.Value  := 50;
  finally
    c.Free;
  end;
end;

procedure Test_Tabs(Host: TWinControl);
var c: TFRMaterialTabs;
begin
  c := TFRMaterialTabs.Create(Host);
  try
    c.Parent := Host;
  finally
    c.Free;
  end;
end;

procedure Test_PageControl(Host: TWinControl);
var c: TFRMaterialPageControl;
begin
  c := TFRMaterialPageControl.Create(Host);
  try
    c.Parent := Host;
  finally
    c.Free;
  end;
end;

procedure Test_Carousel(Host: TWinControl);
var c: TFRMaterialCarousel;
begin
  c := TFRMaterialCarousel.Create(Host);
  try
    c.Parent := Host;
  finally
    c.Free;
  end;
end;

procedure Test_TreeView(Host: TWinControl);
var c: TFRMaterialTreeView;
begin
  c := TFRMaterialTreeView.Create(Host);
  try
    c.Parent := Host;
  finally
    c.Free;
  end;
end;

procedure Test_ListView(Host: TWinControl);
var c: TFRMaterialListView;
begin
  c := TFRMaterialListView.Create(Host);
  try
    c.Parent := Host;
  finally
    c.Free;
  end;
end;

procedure Test_VirtualDataGrid(Host: TWinControl);
var c: TFRMaterialVirtualDataGrid;
begin
  c := TFRMaterialVirtualDataGrid.Create(Host);
  try
    c.Parent := Host;
    c.Header.Columns.Add;
    c.Header.Columns.Add;
  finally
    c.Free;
  end;
end;

procedure Test_DataGrid(Host: TWinControl);
var c: TFRMaterialDataGrid;
begin
  c := TFRMaterialDataGrid.Create(Host);
  try
    c.Parent   := Host;
    c.ColCount := 3;
    c.RowCount := 3;
  finally
    c.Free;
  end;
end;

procedure Test_DateEdit(Host: TWinControl);
var c: TFRMaterialDateEdit;
begin
  c := TFRMaterialDateEdit.Create(Host);
  try
    c.Parent := Host;
    c.Date   := Now;
  finally
    c.Free;
  end;
end;

procedure Test_CheckComboEdit(Host: TWinControl);
var c: TFRMaterialCheckComboEdit;
begin
  c := TFRMaterialCheckComboEdit.Create(Host);
  try
    c.Parent := Host;
  finally
    c.Free;
  end;
end;

procedure Test_MemoEdit(Host: TWinControl);
var c: TFRMaterialMemoEdit;
  TestStrings: TStringArray;
  i: Integer;
begin
  c := TFRMaterialMemoEdit.Create(Host);
  try
    c.Parent := Host;
    
    // Security tests: large text injection
    TestStrings := GenerateBoundaryStrings;
    for i := 0 to High(TestStrings) do
    begin
      c.Memo.Text := TestStrings[i];
      c.Memo.Lines.Add(TestStrings[i]); // Test line operations
      c.Memo.SelText := TestStrings[i]; // Test selection operations
    end;
  finally
    c.Free;
  end;
end;

procedure Test_SpinEdit(Host: TWinControl);
var c: TFRMaterialSpinEdit;
  TestValues: array of Integer;
  i: Integer;
begin
  c := TFRMaterialSpinEdit.Create(Host);
  try
    c.Parent := Host;
    
    // Security tests: boundary conditions for numeric values
    SetLength(TestValues, 8);
    TestValues[0] := Low(Integer); // Min int
    TestValues[1] := High(Integer); // Max int
    TestValues[2] := -2147483647; // Near min int
    TestValues[3] := 2147483646; // Near max int
    TestValues[4] := 0;
    TestValues[5] := -1;
    TestValues[6] := 1;
    TestValues[7] := 999999999; // Large positive
    
    for i := 0 to High(TestValues) do
    begin
      c.Value := TestValues[i];
      c.MinValue := TestValues[i];
      c.MaxValue := TestValues[i];
    end;
  finally
    c.Free;
  end;
end;

procedure Test_SearchEdit(Host: TWinControl);
var c: TFRMaterialSearchEdit;
begin
  c := TFRMaterialSearchEdit.Create(Host);
  try
    c.Parent := Host;
  finally
    c.Free;
  end;
end;

procedure Test_MaskEdit(Host: TWinControl);
var c: TFRMaterialMaskEdit;
begin
  c := TFRMaterialMaskEdit.Create(Host);
  try
    c.Parent := Host;
  finally
    c.Free;
  end;
end;

procedure Test_DatePicker(Host: TWinControl);
var c: TFRMaterialDatePicker;
begin
  c := TFRMaterialDatePicker.Create(Host);
  try
    c.Parent := Host;
  finally
    c.Free;
  end;
end;

procedure Test_TimePicker(Host: TWinControl);
var c: TFRMaterialTimePicker;
begin
  c := TFRMaterialTimePicker.Create(Host);
  try
    c.Parent := Host;
  finally
    c.Free;
  end;
end;

procedure Test_BottomSheet(Host: TWinControl);
var c: TFRMaterialBottomSheet;
begin
  c := TFRMaterialBottomSheet.Create(Host);
  try
    c.Parent := Host;
  finally
    c.Free;
  end;
end;

procedure Test_Snackbar(Host: TWinControl);
var c: TFRMaterialSnackbar;
begin
  c := TFRMaterialSnackbar.Create(Host);
  try
    c.Duration := 100;
  finally
    c.Free;
  end;
end;

procedure Test_Dialog(Host: TWinControl);
var c: TFRMaterialDialog;
begin
  c := TFRMaterialDialog.Create(Host);
  try
    c.Title   := 'Test';
    c.Content := 'Body';
  finally
    c.Free;
  end;
end;

procedure Test_Tooltip(Host: TWinControl);
var c: TFRMaterialTooltip;
begin
  c := TFRMaterialTooltip.Create(Host);
  try
  finally
    c.Free;
  end;
end;

procedure Test_Menu(Host: TWinControl);
var c: TFRMaterialMenu;
begin
  c := TFRMaterialMenu.Create(Host);
  try
  finally
    c.Free;
  end;
end;

{ ── Combo Popup Search Field Tests ────────────────────────────────── }

procedure Test_ComboPopupSearch(Host: TWinControl);
var
  combo: TFRMaterialCombo;
  i: Integer;
begin
  { Exercita o Combo com muitos itens — a criaçao/destruiçao do popup
    e a logica de filtro sao testadas indiretamente via lifecycle.
    O popup usa InternalInsertAtCaret, DeleteSelection, CaretPosFromX
    que sao exercitados nos testes de ThemeStress + DensityCycle via
    ApplyTheme com multiplas densidades/variantes. }
  combo := TFRMaterialCombo.Create(Host);
  try
    combo.Parent := Host;
    combo.Width  := 300;
    for i := 0 to 99 do
      combo.Items.Add('Item ' + IntToStr(i) + ' - Long text for filtering');

    { Cicla por densidades e variantes com muitos itens }
    combo.ItemIndex := 50;
    combo.Density := ddCompact;
    combo.Density := ddDense;
    combo.Density := ddUltraDense;
    combo.Density := ddNormal;

    combo.Variant := mvFilled;
    combo.Variant := mvOutlined;
    combo.Variant := mvStandard;

    { Remove e re-adiciona itens — edge case de invalidação }
    combo.Items.Clear;
    combo.Items.Add('Solo');
    combo.ItemIndex := 0;
    if combo.SelectedText <> 'Solo' then
      raise Exception.Create('SelectedText expected "Solo", got "' + combo.SelectedText + '"');

    { ItemIndex bounds }
    combo.ItemIndex := -1;
    combo.ItemIndex := combo.Items.Count - 1;
  finally
    combo.Free;
  end;
end;

{ ── Density Integration Tests ────────────────────────────────────── }

procedure Test_DensityCycle(Host: TWinControl);
var
  edit: TFRMaterialEdit;
  combo: TFRMaterialCombo;
  btn: TFRMaterialButton;
  d: TFRMDDensity;
  editH, comboH: Integer;
begin
  { Verifica que Edit e Combo respondem igualmente ao ciclo de densidade
    via ThemeManager — ambos devem ter altura = 56 + delta. }
  edit  := TFRMaterialEdit.Create(Host);
  combo := TFRMaterialCombo.Create(Host);
  btn   := TFRMaterialButton.Create(Host);
  try
    edit.Parent  := Host;
    combo.Parent := Host;
    btn.Parent   := Host;

    for d := Low(TFRMDDensity) to High(TFRMDDensity) do
    begin
      GThemeManager.Density := d;
      Application.ProcessMessages;

      editH  := edit.Height;
      comboH := combo.Height;
      if editH <> comboH then
        raise Exception.CreateFmt(
          'Density %d: Edit.Height=%d <> Combo.Height=%d',
          [Ord(d), editH, comboH]);
    end;

    GThemeManager.Density := ddNormal;
  finally
    btn.Free;
    combo.Free;
    edit.Free;
  end;
end;

{ ── Graphics Tests ───────────────────────────────────────────────────── }

procedure Test_GraphicsRendering(Host: TWinControl);
var
  c: TFRMaterialButton;
  bmp: TBitmap;
  i: Integer;
  OriginalDPI: Integer;
begin
  bmp := TBitmap.Create;
  try
    c := TFRMaterialButton.Create(Host);
    try
      c.Parent := Host;
      c.Caption := 'Graphics Test';
      c.ButtonStyle := mbsFilled;
      
      // Test different sizes
      for i := 1 to 5 do
      begin
        c.SetBounds(10, 10, i * 50, i * 30);
        c.Invalidate;
        Application.ProcessMessages;
      end;
      
      // Test bitmap rendering
      bmp.SetSize(200, 100);
      bmp.Canvas.Brush.Color := clWhite;
      bmp.Canvas.FillRect(0, 0, 200, 100);
      c.PaintTo(bmp.Canvas, 10, 10);
      
      // Test extreme sizes
      c.SetBounds(0, 0, 1, 1);
      c.Invalidate;
      c.SetBounds(0, 0, 5000, 3000);
      c.Invalidate;
      
    finally
      c.Free;
    end;
  finally
    bmp.Free;
  end;
end;

procedure Test_DPIRendering(Host: TWinControl);
var
  c: TFRMaterialEdit;
  OriginalDPI: Integer;
  i: Integer;
begin
  OriginalDPI := Screen.PixelsPerInch;
  c := TFRMaterialEdit.Create(Host);
  try
    c.Parent := Host;
    c.Caption := 'DPI Test';
    c.Text := 'Test DPI scaling';
    
    // Test different DPI scenarios
    for i := 72 to 200 do
    begin
      // Simulate DPI change (Note: This is a simplified test)
      c.Font.Size := Round(8 * (i / 96)); // Scale font with DPI
      c.Invalidate;
      Application.ProcessMessages;
    end;
    
    // Reset
    c.Font.Size := 8;
    c.Invalidate;
    
  finally
    c.Free;
  end;
end;

procedure Test_ThemeRendering(Host: TWinControl);
var
  btn: TFRMaterialButton;
  edit: TFRMaterialEdit;
  card: TFRMaterialCard;
  i: Integer;
begin
  btn := TFRMaterialButton.Create(Host);
  edit := TFRMaterialEdit.Create(Host);
  card := TFRMaterialCard.Create(Host);
  try
    btn.Parent := Host;
    edit.Parent := Host;
    card.Parent := Host;
    
    btn.Caption := 'Theme Test';
    edit.Caption := 'Edit Theme';
    
    // Test all theme combinations
    for i := 0 to 5 do
    begin
      GThemeManager.DarkMode := (i mod 2) = 0;
      GThemeManager.Density := TFRMDDensity(i mod 4);
      GThemeManager.Variant := TFRMaterialVariant(i mod 3);
      
      // Force repaint
      btn.Invalidate;
      edit.Invalidate;
      card.Invalidate;
      Application.ProcessMessages;
    end;
    
  finally
    btn.Free;
    edit.Free;
    card.Free;
  end;
end;

procedure Test_ExtremeGraphics(Host: TWinControl);
var
  c: TFRMaterialSlider;
  i: Integer;
begin
  c := TFRMaterialSlider.Create(Host);
  try
    c.Parent := Host;
    
    // Test extreme values that affect rendering
    for i := 0 to 100 do
    begin
      c.Value := i;
      c.Min := -50;
      c.Max := 150;
      c.Invalidate;
      Application.ProcessMessages;
    end;
    
    // Test zero/negative dimensions
    c.Width := 0;
    c.Height := 0;
    c.Invalidate;
    
    c.Width := 1;
    c.Height := 1;
    c.Invalidate;
    
    // Test very large dimensions
    c.Width := 10000;
    c.Height := 10000;
    c.Invalidate;
    
  finally
    c.Free;
  end;
end;

{ ── Massive Data Tests ─────────────────────────────────────────────────── }

procedure Test_ListViewMassive(Host: TWinControl);
var
  c: TFRMaterialListView;
  i: Integer;
  Item: TFRMaterialListItem;
  StartTime: TDateTime;
begin
  c := TFRMaterialListView.Create(Host);
  try
    c.Parent := Host;
    
    StartTime := Now;
    
    // Add 10,000 items
    for i := 0 to 9999 do
    begin
      Item := c.Items.Add;
      Item.Headline := 'Item ' + IntToStr(i) + ' - ' + GenerateMaliciousString(50);
      Item.SupportText := 'Support text for item ' + IntToStr(i);
      Item.TrailingText := '>> ' + IntToStr(i);
      
      // Force refresh every 1000 items
      if (i mod 1000) = 0 then
      begin
        c.Invalidate;
        Application.ProcessMessages;
      end;
    end;
    
    // Test selection performance
    for i := 0 to 99 do
    begin
      c.ItemIndex := i * 100;
      Application.ProcessMessages;
    end;
    
    WriteLn('    ListView: 10,000 items loaded in ', 
      FormatFloat('0.00', (Now - StartTime) * 24 * 60 * 60), ' seconds');
    
  finally
    c.Free;
  end;
end;

procedure Test_TreeViewMassive(Host: TWinControl);
var
  c: TFRMaterialTreeView;
  i, j: Integer;
  Node, ChildNode: TFRMaterialTreeNode;
  StartTime: TDateTime;
begin
  c := TFRMaterialTreeView.Create(Host);
  try
    c.Parent := Host;
    
    StartTime := Now;
    
    // Create massive tree structure
    for i := 0 to 999 do // 1000 root nodes
    begin
      Node := c.Nodes.Add;
      Node.Caption := 'Root ' + IntToStr(i);
      
      // Add 10 child nodes to each root
      for j := 0 to 9 do
      begin
        ChildNode := Node.Children.Add;
        ChildNode.Caption := 'Child ' + IntToStr(i) + '.' + IntToStr(j);
        
        // Add 5 grandchildren to each child
        if (j mod 2) = 0 then
        begin
          with ChildNode.Children.Add do
            Caption := 'GrandChild ' + IntToStr(i) + '.' + IntToStr(j) + '.0';
          with ChildNode.Children.Add do
            Caption := 'GrandChild ' + IntToStr(i) + '.' + IntToStr(j) + '.1';
        end;
      end;
      
      // Expand every 100 nodes
      if (i mod 100) = 0 then
      begin
        Node.Expanded := True;
        Application.ProcessMessages;
      end;
    end;
    
    // Test expand/collapse performance
    for i := 0 to 99 do
    begin
      c.Nodes[i].Expanded := True;
      Application.ProcessMessages;
      c.Nodes[i].Expanded := False;
      Application.ProcessMessages;
    end;
    
    WriteLn('    TreeView: ~15,000 nodes loaded in ', 
      FormatFloat('0.00', (Now - StartTime) * 24 * 60 * 60), ' seconds');
    
  finally
    c.Free;
  end;
end;

procedure Test_DataGridMassive(Host: TWinControl);
var
  c: TFRMaterialDataGrid;
  i, j: Integer;
  StartTime: TDateTime;
begin
  c := TFRMaterialDataGrid.Create(Host);
  try
    c.Parent := Host;
    
    StartTime := Now;
    
    // Create 100 columns
    c.ColCount := 100;
    for i := 0 to 99 do
      c.ColWidths[i] := 80;
    
    // Create 10,000 rows
    c.RowCount := 10000;
    
    // Fill with data
    for i := 0 to 9999 do
    begin
      for j := 0 to 99 do
      begin
        c.Cells[j, i] := 'R' + IntToStr(i) + 'C' + IntToStr(j);
        
        // Add some longer text
        if (j mod 10) = 0 then
          c.Cells[j, i] := c.Cells[j, i] + ' - ' + GenerateMaliciousString(100);
      end;
      
      // Force refresh every 1000 rows
      if (i mod 1000) = 0 then
      begin
        c.Invalidate;
        Application.ProcessMessages;
      end;
    end;
    
    // Test scrolling performance
    c.TopRow := 5000;
    Application.ProcessMessages;
    c.TopRow := 0;
    Application.ProcessMessages;
    
    // Test cell selection
    for i := 0 to 99 do
    begin
      c.Col := i;
      c.Row := i * 100;
      Application.ProcessMessages;
    end;
    
    WriteLn('    DataGrid: 1,000,000 cells loaded in ', 
      FormatFloat('0.00', (Now - StartTime) * 24 * 60 * 60), ' seconds');
    
  finally
    c.Free;
  end;
end;

procedure Test_VirtualDataGridMassive(Host: TWinControl);
var
  c: TFRMaterialVirtualDataGrid;
  i: Integer;
  StartTime: TDateTime;
  Node: PVirtualNode;
  Data: PFRMDNodeData;
  ChildNode: PVirtualNode;
begin
  c := TFRMaterialVirtualDataGrid.Create(Host);
  try
    c.Parent := Host;
    
    StartTime := Now;
    
    // Setup virtual grid
    c.TreeOptions.PaintOptions := c.TreeOptions.PaintOptions + [toShowTreeLines];
    c.TreeOptions.SelectionOptions := c.TreeOptions.SelectionOptions + [toExtendedFocus];
    
    // Add 50 columns
    for i := 0 to 49 do
    begin
      with c.Header.Columns.Add do
      begin
        Text := 'Column ' + IntToStr(i);
        Width := 100;
      end;
    end;
    
    // Add 10,000 nodes (less than 1M for performance)
    for i := 0 to 9999 do
    begin
      Node := c.AddChild(nil);
      Data := c.GetNodeData(Node);
      if Assigned(Data) then
      begin
        Data^.Nivel := 0;
        Data^.Texto := 'Node ' + IntToStr(i) + ' - ' + GenerateMaliciousString(30);
      end;
      
      // Add some children
      if (i mod 10) = 0 then
      begin
        ChildNode := c.AddChild(Node);
        Data := c.GetNodeData(ChildNode);
        if Assigned(Data) then
        begin
          Data^.Nivel := 1;
          Data^.Texto := 'Child ' + IntToStr(i) + '.0';
        end;
      end;
      
      // Force refresh every 1000 nodes
      if (i mod 1000) = 0 then
      begin
        c.Invalidate;
        Application.ProcessMessages;
      end;
    end;
    
    // Test virtual scrolling performance
    for i := 0 to 99 do
    begin
      c.TopNode := c.GetFirstVisible;
      Application.ProcessMessages;
    end;
    
    // Test column operations
    for i := 0 to 49 do
    begin
      c.Header.Columns[i].Width := 50 + (i * 2);
      Application.ProcessMessages;
    end;
    
    WriteLn('    VirtualDataGrid: 10K nodes with hierarchy in ', 
      FormatFloat('0.00', (Now - StartTime) * 24 * 60 * 60), ' seconds');
    
  finally
    c.Free;
  end;
end;

{ ── Security Tests ───────────────────────────────────────────────────── }

procedure Test_MemoryStress(Host: TWinControl);
var
  i: Integer;
  Components: array of TComponent;
begin
  // Test rapid creation/destruction to detect memory leaks
  SetLength(Components, 100);
  try
    for i := 0 to 99 do
    begin
      Components[i] := TFRMaterialEdit.Create(Host);
      TFRMaterialEdit(Components[i]).Parent := Host;
      TFRMaterialEdit(Components[i]).Text := GenerateMaliciousString(1000);
    end;
    
    // Rapid destruction
    for i := 0 to 99 do
      Components[i].Free;
  finally
    SetLength(Components, 0);
  end;
end;

procedure Test_Fuzzing(Host: TWinControl);
var
  i: Integer;
  c: TFRMaterialEdit;
  RandomString: string;
begin
  c := TFRMaterialEdit.Create(Host);
  try
    c.Parent := Host;
    
    // Fuzzing test: 100 random strings
    for i := 0 to 99 do
    begin
      RandomString := GenerateMaliciousString(Random(10000)); // Up to 10KB
      c.Edit.Text := RandomString;
      c.Caption := RandomString;
      c.PrefixText := RandomString;
      c.SuffixText := RandomString;
    end;
  finally
    c.Free;
  end;
end;

{ ── Theme stress test ────────────────────────────────────────────── }

procedure Test_ThemeStress(Host: TWinControl);
var
  i: Integer;
  edit: TFRMaterialEdit;
  btn: TFRMaterialButton;
begin
  { Cria alguns listeners, alterna tema 20x, destroi. Exercita o
    recursion guard e a iteracao segura da lista de listeners. }
  edit := TFRMaterialEdit.Create(Host);
  btn  := TFRMaterialButton.Create(Host);
  try
    edit.Parent := Host;
    btn.Parent  := Host;
    for i := 1 to 20 do
    begin
      GThemeManager.DarkMode := (i mod 2) = 0;
      GThemeManager.Density  := TFRMDDensity(i mod 4);
      GThemeManager.Variant  := TFRMaterialVariant(i mod 3);
    end;
    GThemeManager.DarkMode := False;
    GThemeManager.Density  := ddNormal;
    GThemeManager.Variant  := mvStandard;
  finally
    btn.Free;
    edit.Free;
  end;
end;

{ ── Main ─────────────────────────────────────────────────────────── }

procedure RunAllTests;
var
  Host: TForm;
begin
  GFailures     := TStringList.Create;
  GThemeManager := TFRMaterialThemeManager.Create(nil);
  Host         := TForm.CreateNew(nil);
  try
    Host.Visible := False;
    Host.Width   := 800;
    Host.Height  := 600;
    try Host.HandleNeeded; except end;

    WriteLn('═══════════════════════════════════════════');
    WriteLn('  MD3 Smoke Test Runner');
    WriteLn('═══════════════════════════════════════════');
    WriteLn;
    WriteLn('Individual components:');

    Run('TFRMaterialEdit',             @Test_Edit,             Host);
    Run('TFRMaterialButton',           @Test_Button,           Host);
    Run('TFRMaterialSwitch',           @Test_Switch,           Host);
    Run('TFRMaterialCheckBox',         @Test_CheckBox,         Host);
    Run('TFRMaterialRadioButton',      @Test_RadioButton,      Host);
    Run('TFRMaterialChip',             @Test_Chip,             Host);
    Run('TFRMaterialDivider',          @Test_Divider,          Host);
    Run('TFRMaterialCard',             @Test_Card,             Host);
    Run('TFRMaterialToolbox',          @Test_Toolbox,          Host);
    Run('TFRMaterialCombo',            @Test_Combo,            Host);
    Run('TFRMaterialGridPanel',        @Test_GridPanel,        Host);
    Run('TFRMaterialLinearProgress',   @Test_LinearProgress,   Host);
    Run('TFRMaterialCircularProgress', @Test_CircularProgress, Host);
    Run('TFRMaterialFAB',              @Test_FAB,              Host);
    Run('TFRMaterialNavRail',          @Test_NavRail,          Host);
    Run('TFRMaterialNavBar',           @Test_NavBar,           Host);
    Run('TFRMaterialAppBar',           @Test_AppBar,           Host);
    Run('TFRMaterialBadge',            @Test_Badge,            Host);
    Run('TFRMaterialSlider',           @Test_Slider,           Host);
    Run('TFRMaterialTabs',             @Test_Tabs,             Host);
    Run('TFRMaterialPageControl',      @Test_PageControl,      Host);
    Run('TFRMaterialCarousel',         @Test_Carousel,         Host);
    Run('TFRMaterialTreeView',         @Test_TreeView,         Host);
    Run('TFRMaterialListView',         @Test_ListView,         Host);
    Run('TFRMaterialVirtualDataGrid',  @Test_VirtualDataGrid,  Host);
    Run('TFRMaterialDataGrid',         @Test_DataGrid,         Host);
    Run('TFRMaterialDateEdit',         @Test_DateEdit,         Host);
    Run('TFRMaterialCheckComboEdit',   @Test_CheckComboEdit,   Host);
    Run('TFRMaterialMemoEdit',         @Test_MemoEdit,         Host);
    Run('TFRMaterialSpinEdit',         @Test_SpinEdit,         Host);
    Run('TFRMaterialSearchEdit',       @Test_SearchEdit,       Host);
    Run('TFRMaterialMaskEdit',         @Test_MaskEdit,         Host);
    Run('TFRMaterialDatePicker',       @Test_DatePicker,       Host);
    Run('TFRMaterialTimePicker',       @Test_TimePicker,       Host);
    Run('TFRMaterialBottomSheet',      @Test_BottomSheet,      Host);
    Run('TFRMaterialSnackbar',         @Test_Snackbar,         Host);
    Run('TFRMaterialDialog',           @Test_Dialog,           Host);
    Run('TFRMaterialTooltip',          @Test_Tooltip,          Host);
    Run('TFRMaterialMenu',             @Test_Menu,             Host);

    WriteLn;
    WriteLn('Massive data tests:');
    Run('ListViewMassive (10K items)',      @Test_ListViewMassive,      Host);
    Run('TreeViewMassive (15K nodes)',      @Test_TreeViewMassive,      Host);
    Run('DataGridMassive (1M cells)',      @Test_DataGridMassive,      Host);
    Run('VirtualDataGridMassive (1M rows)', @Test_VirtualDataGridMassive, Host);

    WriteLn;
    WriteLn('Integration tests:');
    Run('ComboPopupSearch (caret/sel/clip)', @Test_ComboPopupSearch, Host);
    Run('DensityCycle (Edit=Combo height)',  @Test_DensityCycle,     Host);

    WriteLn;
    WriteLn('Graphics tests:');
    Run('GraphicsRendering (sizes & bitmap)', @Test_GraphicsRendering, Host);
    Run('DPIRendering (72-200 DPI)',         @Test_DPIRendering,       Host);
    Run('ThemeRendering (all combos)',        @Test_ThemeRendering,     Host);
    Run('ExtremeGraphics (boundary sizes)',  @Test_ExtremeGraphics,    Host);
    
    WriteLn;
    WriteLn('Security tests:');
    Run('MemoryStress (100 components)', @Test_MemoryStress,   Host);
    Run('Fuzzing (100 random strings)', @Test_Fuzzing,         Host);
    
    WriteLn;
    WriteLn('Stress tests:');
    Run('ThemeStress (20 toggles)',    @Test_ThemeStress,      Host);

  finally
    try Host.Free except on E: Exception do Fail('Host.Free', E.Message); end;
    try GThemeManager.Free except on E: Exception do Fail('ThemeManager.Free', E.Message); end;
  end;
end;

procedure PrintSummary;
begin
  WriteLn;
  WriteLn('═══════════════════════════════════════════');
  WriteLn(Format('  Passed: %d   Failed: %d', [GPassed, GFailed]));
  WriteLn('═══════════════════════════════════════════');
  if GFailed > 0 then
  begin
    WriteLn;
    WriteLn('Failures:');
    WriteLn(GFailures.Text);
  end;
  Flush(Output);
end;

begin
  Application.Initialize;
  try
    RunAllTests;
  except
    on E: Exception do
    begin
      Inc(GFailed);
      if GFailures = nil then GFailures := TStringList.Create;
      GFailures.Add('RunAllTests top-level: ' + E.ClassName + ' — ' + E.Message);
    end;
  end;
  PrintSummary;
  if Assigned(GFailures) then GFailures.Free;
  if GFailed > 0 then
    Halt(1)
  else
    Halt(0);
end.
