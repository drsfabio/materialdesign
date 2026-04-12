unit FRMaterial3Toolbox;

{$mode objfpc}{$H+}

{ Material Design 3 — Toolbox.

  TFRMaterialToolbox — container flat para hospedar controles filhos
    (buttons, icon buttons, chips, etc.) com auto-layout horizontal
    ou vertical e spacing uniforme.

  Nao herda de TToolBar / TToolBox legado. Construido em cima de
  TCustomControl com MD3 tokens (Surface / SurfaceContainer / Outline)
  e shape scale para cantos arredondados. Conteudo eh layouted no
  AlignControls para nao depender de Align/Anchors manuais nos filhos.

  Uso tipico:
    Toolbox.Orientation := toHorizontal;
    Toolbox.ToolboxStyle := tsFilled;
    Button1.Parent := Toolbox;
    Button2.Parent := Toolbox;
  -> os dois botoes sao dispostos lado a lado com gap de 8px.

  License: LGPL v3
}

interface

uses
  Classes, SysUtils, Math, Controls, Graphics,
  {$IFDEF FPC} LCLType, LCLIntf, LResources, {$ENDIF}
  BGRABitmap, BGRABitmapTypes, FRMaterial3Base, FRMaterialTheme;

type
  TFRMDToolboxStyle = (
    tsFilled,    { SurfaceContainer background, sem borda }
    tsOutlined,  { Surface background, OutlineVariant border }
    tsElevated,  { SurfaceContainerLow + shadow Level1 }
    tsFlat       { parent-color transparente — so layout, sem chrome }
  );

  TFRMDToolboxOrientation = (toHorizontal, toVertical);

  { TFRMaterialToolbox }

  TFRMaterialToolbox = class(TCustomControl, IFRMaterialComponent)
  private
    FToolboxStyle: TFRMDToolboxStyle;
    FOrientation: TFRMDToolboxOrientation;
    FBorderRadius: Integer;
    FContentPadding: Integer;
    FItemSpacing: Integer;
    FSyncWithTheme: TFRMDSyncOptions;
    procedure SetToolboxStyle(AValue: TFRMDToolboxStyle);
    procedure SetOrientation(AValue: TFRMDToolboxOrientation);
    procedure SetBorderRadius(AValue: Integer);
    procedure SetContentPadding(AValue: Integer);
    procedure SetItemSpacing(AValue: Integer);
    procedure GetStyleColors(out ABg, ABorder: TColor;
      out AElevation: TFRMDElevation);
  protected
    procedure Paint; override;
    procedure EraseBackground({%H-}DC: HDC); override;
    procedure AlignControls(AControl: TControl; var ARect: TRect); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ApplyTheme(const AThemeManager: TObject); virtual;
  published
    property ToolboxStyle: TFRMDToolboxStyle read FToolboxStyle write SetToolboxStyle default tsFilled;
    property Orientation: TFRMDToolboxOrientation read FOrientation write SetOrientation default toHorizontal;
    property BorderRadius: Integer read FBorderRadius write SetBorderRadius default 12;
    property ContentPadding: Integer read FContentPadding write SetContentPadding default 8;
    property ItemSpacing: Integer read FItemSpacing write SetItemSpacing default 8;
    property SyncWithTheme: TFRMDSyncOptions read FSyncWithTheme write FSyncWithTheme default [toColor];
    property Align;
    property Anchors;
    property BorderSpacing;
    property Color;
    property Constraints;
    property Cursor;
    property Enabled;
    property Font;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;
    property OnClick;
    property OnMouseDown;
    property OnMouseUp;
    property OnMouseMove;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnResize;
  end;

procedure Register;

implementation

procedure Register;
begin
  { Icon reutiliza o do AppBar ate gerar um dedicado para Toolbox. }
  {$IFDEF FPC}
    {$I icons\frmaterialappbar_icon.lrs}
  {$ENDIF}
  RegisterComponents('Material Design 3', [TFRMaterialToolbox]);
end;

{ TFRMaterialToolbox }

constructor TFRMaterialToolbox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FRMDRegisterComponent(Self);

  ControlStyle := ControlStyle + [csAcceptsControls, csCaptureMouse];
  FToolboxStyle   := tsFilled;
  FOrientation    := toHorizontal;
  FBorderRadius   := 12;
  FContentPadding := 8;
  FItemSpacing    := 8;
  FSyncWithTheme  := [toColor];

  Width  := 320;
  Height := 56;
end;

destructor TFRMaterialToolbox.Destroy;
begin
  FRMDUnregisterComponent(Self);
  inherited Destroy;
end;

procedure TFRMaterialToolbox.ApplyTheme(const AThemeManager: TObject);
begin
  if not Assigned(AThemeManager) then Exit;
  FRMDSafeInvalidate(Self);
end;

procedure TFRMaterialToolbox.SetToolboxStyle(AValue: TFRMDToolboxStyle);
begin
  if FToolboxStyle = AValue then Exit;
  FToolboxStyle := AValue;
  FRMDSafeInvalidate(Self);
end;

procedure TFRMaterialToolbox.SetOrientation(AValue: TFRMDToolboxOrientation);
begin
  if FOrientation = AValue then Exit;
  FOrientation := AValue;
  ReAlign;
  FRMDSafeInvalidate(Self);
end;

procedure TFRMaterialToolbox.SetBorderRadius(AValue: Integer);
begin
  if AValue < 0 then AValue := 0;
  if FBorderRadius = AValue then Exit;
  FBorderRadius := AValue;
  FRMDSafeInvalidate(Self);
end;

procedure TFRMaterialToolbox.SetContentPadding(AValue: Integer);
begin
  if AValue < 0 then AValue := 0;
  if FContentPadding = AValue then Exit;
  FContentPadding := AValue;
  ReAlign;
  FRMDSafeInvalidate(Self);
end;

procedure TFRMaterialToolbox.SetItemSpacing(AValue: Integer);
begin
  if AValue < 0 then AValue := 0;
  if FItemSpacing = AValue then Exit;
  FItemSpacing := AValue;
  ReAlign;
  FRMDSafeInvalidate(Self);
end;

procedure TFRMaterialToolbox.GetStyleColors(out ABg, ABorder: TColor;
  out AElevation: TFRMDElevation);
begin
  AElevation := elLevel0;
  ABorder    := clNone;
  case FToolboxStyle of
    tsFilled:
    begin
      ABg := MD3Colors.SurfaceContainer;
    end;
    tsOutlined:
    begin
      ABg := MD3Colors.Surface;
      ABorder := MD3Colors.OutlineVariant;
    end;
    tsElevated:
    begin
      ABg := MD3Colors.SurfaceContainerLow;
      AElevation := elLevel1;
    end;
    tsFlat:
    begin
      if Parent <> nil then
        ABg := Parent.Brush.Color
      else
        ABg := MD3Colors.Surface;
    end;
  end;
end;

procedure TFRMaterialToolbox.EraseBackground(DC: HDC);
var
  ARect: TRect;
begin
  if DC = 0 then Exit;
  ARect := Rect(0, 0, Width, Height);
  if Parent <> nil then
    Brush.Color := Parent.Brush.Color
  else
    Brush.Color := MD3Colors.Surface;
  LCLIntf.FillRect(DC, ARect, HBRUSH(Brush.Reference.Handle));
end;

procedure TFRMaterialToolbox.Paint;
var
  bmp: TBGRABitmap;
  bgColor, borderColor: TColor;
  elev: TFRMDElevation;
begin
  if not FRMDCanPaint(Self) then Exit;

  bmp := TBGRABitmap.Create(Width, Height, BGRAPixelTransparent);
  try
    GetStyleColors(bgColor, borderColor, elev);

    if elev > elLevel0 then
      MD3DrawShadow(bmp, 0, 0, Width, Height, FBorderRadius, elev);

    if FToolboxStyle <> tsFlat then
      MD3FillRoundRect(bmp, 0, 0, Width, Height, FBorderRadius, bgColor);

    if borderColor <> clNone then
      MD3RoundRect(bmp, 0.5, 0.5, Width - 0.5, Height - 0.5,
        FBorderRadius, borderColor, 1.0);

    bmp.Draw(Canvas, 0, 0, False);
  finally
    bmp.Free;
  end;

  inherited Paint;
end;

procedure TFRMaterialToolbox.AlignControls(AControl: TControl;
  var ARect: TRect);
var
  i, X, Y, AvailW, AvailH: Integer;
  Child: TControl;
begin
  inherited AlignControls(AControl, ARect);

  if csDestroying in ComponentState then Exit;
  if csLoading in ComponentState then Exit;
  if ControlCount = 0 then Exit;

  { Auto-layout: distribui os filhos sequencialmente na orientacao
    configurada, respeitando padding e spacing. Filhos com Align <> alNone
    sao ignorados aqui — seguem a logica LCL normal. }
  X := FContentPadding;
  Y := FContentPadding;
  AvailW := Width - FContentPadding * 2;
  AvailH := Height - FContentPadding * 2;

  for i := 0 to ControlCount - 1 do
  begin
    Child := Controls[i];
    if Child = nil then Continue;
    if not Child.Visible then Continue;
    if Child.Align <> alNone then Continue;

    if FOrientation = toHorizontal then
    begin
      Child.Left := X;
      Child.Top  := FContentPadding + Max(0, (AvailH - Child.Height) div 2);
      Inc(X, Child.Width + FItemSpacing);
    end
    else
    begin
      Child.Left := FContentPadding + Max(0, (AvailW - Child.Width) div 2);
      Child.Top  := Y;
      Inc(Y, Child.Height + FItemSpacing);
    end;
  end;
end;

end.
