unit FRMaterial3GridPanel;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, LMessages,
  FRMaterialTheme, FRMaterial3Base;

type

  TFRMaterialGridPanel = class;

  { ── TFRGridItem ──
    Each child control inside the grid panel has a corresponding
    TFRGridItem in the Items collection. When you drop a control
    into the panel in the IDE, an item is auto-created.
    Set ColSpan in the Object Inspector. }

  TFRGridItem = class(TCollectionItem)
  private
    FControl: TControl;
    FColSpan: Integer;
    procedure SetControl(AValue: TControl);
    procedure SetColSpan(AValue: Integer);
    function GetGrid: TFRMaterialGridPanel;
  protected
    function GetDisplayName: string; override;
  published
    property Control: TControl read FControl write SetControl;
    property ColSpan: Integer read FColSpan write SetColSpan default 12;
  end;

  { ── TFRGridItems ── }

  TFRGridItems = class(TOwnedCollection)
  private
    function GetGrid: TFRMaterialGridPanel;
    function GetItem(AIndex: Integer): TFRGridItem;
    procedure SetItem(AIndex: Integer; AValue: TFRGridItem);
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    function Add: TFRGridItem;
    function FindByControl(AControl: TControl): TFRGridItem;
    property Items[AIndex: Integer]: TFRGridItem read GetItem write SetItem; default;
  end;

  { TFRMaterialGridPanel
    ─────────────────────────────────────────────────────
    Auto-flow grid layout with 12-column system (MD3).
    Drop child controls inside and set their ColSpan
    via the Items collection in the Object Inspector.
  }

  TFRMaterialGridPanel = class(TCustomControl, IFRMaterialComponent)
  private
    FColumnCount: Integer;
    FGapH: Integer;
    FGapV: Integer;
    FItems: TFRGridItems;
    FUpdating: Boolean;
    FAutoColSpan: Boolean;

    procedure SetColumnCount(AValue: Integer);
    procedure SetGapH(AValue: Integer);
    procedure SetGapV(AValue: Integer);
    procedure SetItems(AValue: TFRGridItems);
    procedure SetAutoColSpan(AValue: Boolean);
    function  ResolveSpan(AControl: TControl): Integer;

  protected
    procedure AlignControls(AControl: TControl; var ARect: TRect); override;
    procedure Paint; override;
    procedure CMControlChange(var Msg: TLMessage); message CM_CONTROLCHANGE;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure SetColSpan(AControl: TControl; ASpan: Integer);
    function  GetColSpan(AControl: TControl): Integer;
    procedure ApplyTheme(const AThemeManager: TObject); virtual;

  published
    property ColumnCount: Integer read FColumnCount write SetColumnCount default 12;
    { GapH / GapV — defaults com respiro suficiente para variantes sem borda
      (Standard/Filled) sob densidades compactas. Reduza explicitamente no
      LFM se quiser um layout mais denso. }
    property GapH: Integer read FGapH write SetGapH default 20;
    property GapV: Integer read FGapV write SetGapV default 16;
    { Quando True, o ColSpan de cada filho eh resolvido automaticamente a partir
      da property FieldSize do TFRMaterial3Control (fsTiny=2, fsSmall=3,
      fsMedium=4, fsLarge=6, fsHuge=8, fsFull=12). Filhos com FieldSize=fsAuto
      ou que nao sao TFRMaterial3Control caem no fallback fsLarge (6 cols).
      Quando False (default), usa o ColSpan manual definido em Items. }
    property AutoColSpan: Boolean read FAutoColSpan write SetAutoColSpan default False;
    property Items: TFRGridItems read FItems write SetItems;

    property Align;
    property Anchors;
    property BorderSpacing;
    property Color;
    property Enabled;
    property Visible;
    property OnResize;
  end;

procedure Register;

implementation

{ ── Registration ── }

procedure Register;
begin
  RegisterComponents('Material Design 3', [TFRMaterialGridPanel]);
end;

{ ════════════════════════════════════════════════════════
  TFRGridItem
  ════════════════════════════════════════════════════════ }

function TFRGridItem.GetGrid: TFRMaterialGridPanel;
begin
  if (Collection <> nil) and (Collection is TFRGridItems) then
    Result := TFRGridItems(Collection).GetGrid
  else
    Result := nil;
end;

function TFRGridItem.GetDisplayName: string;
begin
  if (FControl <> nil) and (FControl.Name <> '') then
    Result := FControl.Name + ' [' + IntToStr(FColSpan) + ']'
  else
    Result := '(empty) [' + IntToStr(FColSpan) + ']';
end;

procedure TFRGridItem.SetControl(AValue: TControl);
begin
  if FControl = AValue then Exit;
  FControl := AValue;
  Changed(False);
end;

procedure TFRGridItem.SetColSpan(AValue: Integer);
var
  grid: TFRMaterialGridPanel;
begin
  if AValue < 1 then AValue := 1;
  grid := GetGrid;
  if (grid <> nil) and (AValue > grid.ColumnCount) then
    AValue := grid.ColumnCount;
  if FColSpan = AValue then Exit;
  FColSpan := AValue;
  Changed(False);
end;

{ ════════════════════════════════════════════════════════
  TFRGridItems
  ════════════════════════════════════════════════════════ }

function TFRGridItems.GetGrid: TFRMaterialGridPanel;
begin
  if Owner is TFRMaterialGridPanel then
    Result := TFRMaterialGridPanel(Owner)
  else
    Result := nil;
end;

function TFRGridItems.GetItem(AIndex: Integer): TFRGridItem;
begin
  Result := TFRGridItem(inherited Items[AIndex]);
end;

procedure TFRGridItems.SetItem(AIndex: Integer; AValue: TFRGridItem);
begin
  inherited Items[AIndex] := AValue;
end;

function TFRGridItems.Add: TFRGridItem;
begin
  Result := TFRGridItem(inherited Add);
  Result.FColSpan := 12;
end;

function TFRGridItems.FindByControl(AControl: TControl): TFRGridItem;
var
  i: Integer;
begin
  if AControl = nil then Exit(nil);
  for i := 0 to Count - 1 do
    if Items[i].Control = AControl then
      Exit(Items[i]);
  Result := nil;
end;

procedure TFRGridItems.Update(Item: TCollectionItem);
var
  grid: TFRMaterialGridPanel;
begin
  inherited;
  grid := GetGrid;
  if (grid <> nil) and (not grid.FUpdating) then
    grid.ReAlign;
end;

{ ════════════════════════════════════════════════════════
  TFRMaterialGridPanel
  ════════════════════════════════════════════════════════ }

constructor TFRMaterialGridPanel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FRMDRegisterComponent(Self);

  ControlStyle := ControlStyle + [csAcceptsControls];

  FColumnCount := 12;
  FGapH := 20;
  FGapV := 16;
  FUpdating := False;
  FAutoColSpan := False;
  FItems := TFRGridItems.Create(Self, TFRGridItem);

  Width  := 600;
  Height := 200;
end;

destructor TFRMaterialGridPanel.Destroy;
begin
  FRMDUnregisterComponent(Self);
  FreeAndNil(FItems);
  inherited Destroy;
end;

{ ── Property setters ── }

procedure TFRMaterialGridPanel.SetColumnCount(AValue: Integer);
begin
  if AValue < 1  then AValue := 1;
  if AValue > 24 then AValue := 24;
  if FColumnCount = AValue then Exit;
  FColumnCount := AValue;
  ReAlign;
end;

procedure TFRMaterialGridPanel.SetGapH(AValue: Integer);
begin
  if AValue < 0 then AValue := 0;
  if FGapH = AValue then Exit;
  FGapH := AValue;
  ReAlign;
end;

procedure TFRMaterialGridPanel.SetGapV(AValue: Integer);
begin
  if AValue < 0 then AValue := 0;
  if FGapV = AValue then Exit;
  FGapV := AValue;
  ReAlign;
end;

procedure TFRMaterialGridPanel.SetItems(AValue: TFRGridItems);
begin
  FItems.Assign(AValue);
end;

procedure TFRMaterialGridPanel.SetAutoColSpan(AValue: Boolean);
begin
  if FAutoColSpan = AValue then Exit;
  FAutoColSpan := AValue;
  ReAlign;
end;

{ Resolve o ColSpan efetivo de um controle.
  - AutoColSpan=False → usa o ColSpan manual do Items (default 12).
  - AutoColSpan=True:
      * TFRMaterial3Control com FieldSize<>fsAuto → mapeia por FieldSize.
      * TFRMaterial3Control com fsAuto → fallback fsLarge (6 cols).
      * Filho nao-MD3 (TPanel, TLabel...) → respeita ColSpan manual
        do Items, permitindo uso misto de auto + manual no mesmo grid. }
function TFRMaterialGridPanel.ResolveSpan(AControl: TControl): Integer;
var
  size: TFRFieldSize;
begin
  if not FAutoColSpan then
  begin
    Result := GetColSpan(AControl);
    Exit;
  end;

  if not (AControl is TFRMaterial3Control) then
  begin
    Result := GetColSpan(AControl);
    if Result > FColumnCount then Result := FColumnCount;
    Exit;
  end;

  size := TFRMaterial3Control(AControl).FieldSize;

  case size of
    fsTiny:   Result := 2;
    fsSmall:  Result := 3;
    fsMedium: Result := 4;
    fsLarge:  Result := 6;
    fsHuge:   Result := 8;
    fsFull:   Result := 12;
  else
    { fsAuto — fallback: metade da linha (6 cols). }
    Result := 6;
  end;

  if Result > FColumnCount then
    Result := FColumnCount;
end;

{ ── Public ColSpan helpers (code usage) ── }

procedure TFRMaterialGridPanel.SetColSpan(AControl: TControl; ASpan: Integer);
var
  item: TFRGridItem;
begin
  if AControl = nil then Exit;
  item := FItems.FindByControl(AControl);
  if item = nil then
  begin
    item := FItems.Add;
    item.FControl := AControl;
  end;
  item.ColSpan := ASpan;
end;

function TFRMaterialGridPanel.GetColSpan(AControl: TControl): Integer;
var
  item: TFRGridItem;
begin
  item := FItems.FindByControl(AControl);
  if item <> nil then
    Result := item.ColSpan
  else
    Result := FColumnCount;
end;

{ ── Auto-manage items when controls are added/removed ── }

procedure TFRMaterialGridPanel.CMControlChange(var Msg: TLMessage);
var
  ctrl: TControl;
  item: TFRGridItem;
begin
  if (Msg.WParam = 0) or (FItems = nil) then Exit;

  ctrl := TControl(Msg.WParam);
  if Boolean(Msg.LParam) then
  begin
    { Control inserted → auto-create item if not exists }
    if FItems.FindByControl(ctrl) = nil then
    begin
      item := FItems.Add;
      item.FControl := ctrl;
    end;
  end
  else
  begin
    { Control removed → remove item }
    item := FItems.FindByControl(ctrl);
    if item <> nil then
    begin
      FUpdating := True;
      try
        item.Free;
      finally
        FUpdating := False;
      end;
    end;
  end;
end;

procedure TFRMaterialGridPanel.Notification(AComponent: TComponent; Operation: TOperation);
var
  item: TFRGridItem;
begin
  inherited;
  if (Operation = opRemove) and (AComponent is TControl) and (FItems <> nil) then
  begin
    item := FItems.FindByControl(TControl(AComponent));
    if item <> nil then
      item.FControl := nil;
  end;
end;

{ ── Layout engine ── }

procedure TFRMaterialGridPanel.AlignControls(AControl: TControl; var ARect: TRect);
var
  i, col, span: Integer;
  areaW: Integer;
  colW: Double;
  ctrl: TControl;
  cx, cy, cw: Integer;
  rowMaxH: Integer;
begin
  if ControlCount = 0 then Exit;

  areaW := ARect.Right - ARect.Left;
  if areaW <= 0 then Exit;

  colW := (areaW - (FColumnCount - 1) * FGapH) / FColumnCount;
  if colW < 1 then colW := 1;

  col := 0;
  cy := ARect.Top;
  rowMaxH := 0;

  for i := 0 to ControlCount - 1 do
  begin
    ctrl := Controls[i];
    if not ctrl.Visible then Continue;

    span := ResolveSpan(ctrl);
    if span > FColumnCount then span := FColumnCount;

    { Wrap to next row if this child won't fit }
    if (col > 0) and (col + span > FColumnCount) then
    begin
      cy := cy + rowMaxH + FGapV;
      col := 0;
      rowMaxH := 0;
    end;

    cx := ARect.Left + Round(col * (colW + FGapH));
    cw := Round(span * colW + (span - 1) * FGapH);

    ctrl.SetBounds(cx, cy, cw, ctrl.Height);

    if ctrl.Height > rowMaxH then
      rowMaxH := ctrl.Height;

    col := col + span;

    { Row full → advance }
    if col >= FColumnCount then
    begin
      cy := cy + rowMaxH + FGapV;
      col := 0;
      rowMaxH := 0;
    end;
  end;
end;

{ ── Design-time paint (grid guides) ── }

procedure TFRMaterialGridPanel.Paint;
var
  colW: Double;
  i, x: Integer;
  r: TRect;
begin
  if csDesigning in ComponentState then
  begin
    r := ClientRect;
    Canvas.Pen.Color := clSilver;
    Canvas.Pen.Style := psDot;
    Canvas.Brush.Style := bsClear;

    colW := (r.Right - r.Left - (FColumnCount - 1) * FGapH) / FColumnCount;

    for i := 0 to FColumnCount - 1 do
    begin
      x := r.Left + Round(i * (colW + FGapH));
      Canvas.Rectangle(x, r.Top, Round(x + colW), r.Bottom);
    end;
  end;
end;

{ ── Theme ── }

procedure TFRMaterialGridPanel.ApplyTheme(const AThemeManager: TObject);
begin
  if not Assigned(AThemeManager) then Exit;
  Invalidate;
end;

end.
