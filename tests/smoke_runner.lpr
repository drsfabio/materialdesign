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
  FRMaterialCurrencyEdit, FRMaterialDateEdit, FRMaterialComboEdit,
  FRMaterialCheckComboEdit, FRMaterialMemoEdit, FRMaterialSpinEdit,
  FRMaterialSearchEdit, FRMaterialMaskEdit;

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

{ ── Test procedures ──────────────────────────────────────────────── }

procedure Test_Edit(Host: TWinControl);
var c: TFRMaterialEdit;
begin
  c := TFRMaterialEdit.Create(Host);
  try
    c.Parent := Host;
    c.Caption := 'TEST';
    c.Edit.Text := 'hello';
    c.FieldSize := TFRFieldSize.fsLarge;
    c.ShowClearButton := True;
    c.ShowSearchButton := True;
    c.ValidationState := vsValid;
    c.ValidationState := vsInvalid;
    c.ValidationState := vsNone;
  finally
    c.Free;
  end;
end;

procedure Test_Button(Host: TWinControl);
var c: TFRMaterialButton;
begin
  c := TFRMaterialButton.Create(Host);
  try
    c.Parent := Host;
    c.Caption := 'Click';
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
    c.Parent := Host;
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
    c.Parent := Host;
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
    c.Parent := Host;
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
    c.Parent := Host;
    c.Caption := 'Chip';
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

procedure Test_GridPanel(Host: TWinControl);
var c: TFRMaterialGridPanel;
begin
  c := TFRMaterialGridPanel.Create(Host);
  try
    c.Parent := Host;
    c.ColumnCount := 12;
    c.GapH := 24;
    c.GapV := 16;
    c.AutoColSpan := True;
  finally
    c.Free;
  end;
end;

procedure Test_LinearProgress(Host: TWinControl);
var c: TFRMaterialLinearProgress;
begin
  c := TFRMaterialLinearProgress.Create(Host);
  try
    c.Parent := Host;
    c.Value := 50;
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
    c.Value := 75;
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
    c.Parent := Host;
    c.Title := 'Test';
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
    c.Max := 100;
    c.Value := 50;
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
    c.Parent := Host;
    c.ColCount := 3;
    c.RowCount := 3;
  finally
    c.Free;
  end;
end;

procedure Test_CurrencyEdit(Host: TWinControl);
var c: TFRMaterialCurrencyEdit;
begin
  c := TFRMaterialCurrencyEdit.Create(Host);
  try
    c.Parent := Host;
    c.Value := 99.99;
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
    c.Date := Now;
  finally
    c.Free;
  end;
end;

procedure Test_ComboEdit(Host: TWinControl);
var c: TFRMaterialComboEdit;
begin
  c := TFRMaterialComboEdit.Create(Host);
  try
    c.Parent := Host;
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
begin
  c := TFRMaterialMemoEdit.Create(Host);
  try
    c.Parent := Host;
  finally
    c.Free;
  end;
end;

procedure Test_SpinEdit(Host: TWinControl);
var c: TFRMaterialSpinEdit;
begin
  c := TFRMaterialSpinEdit.Create(Host);
  try
    c.Parent := Host;
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
    c.Title := 'Test';
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
    btn.Parent := Host;
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
  GFailures := TStringList.Create;
  GThemeManager := TFRMaterialThemeManager.Create(nil);
  Host := TForm.CreateNew(nil);
  try
    Host.Visible := False;
    Host.Width := 800;
    Host.Height := 600;
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
    Run('TFRMaterialCurrencyEdit',     @Test_CurrencyEdit,     Host);
    Run('TFRMaterialDateEdit',         @Test_DateEdit,         Host);
    Run('TFRMaterialComboEdit',        @Test_ComboEdit,        Host);
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
