unit FRMaterial3Snackbar;

{$mode objfpc}{$H+}

{ Material Design 3 — Snackbar.

  TFRMaterialSnackbar — Non-visual component for showing snackbar notifications.
  Call Show to display at the bottom (or top) of the parent form.

  Features:
    • Slide-up / slide-down entrance animation with EaseOutCubic
    • Fade-out exit animation
    • Multiline support with dynamic height
    • Optional close (X) button
    • Optional leading icon
    • Configurable position (top / bottom)
    • Snackbar types with MD3 color mapping (Default, Info, Success, Warning, Error)
    • OnShow / OnHide events

  License: LGPL v3
}

interface

uses
  Classes, SysUtils, Controls, Graphics, Forms, ExtCtrls,
  {$IFDEF FPC} LResources, {$ENDIF}
  BGRABitmap, BGRABitmapTypes, FRMaterialTheme, FRMaterial3Base,
  FRMaterialIcons;

type
  { Snackbar position }
  TFRMDSnackbarPosition = (spBottom, spTop);

  { Snackbar type — controls color scheme }
  TFRMDSnackbarType = (
    stDefault,   // InverseSurface / InverseOnSurface (MD3 standard)
    stInfo,      // Primary container colors
    stSuccess,   // Tertiary container colors (green-ish)
    stWarning,   // Secondary container colors (amber-ish)
    stError      // Error container colors
  );

  TFRMaterialSnackbar = class(TComponent, IFRMaterialComponent)
  private
    FMessage: string;
    FActionText: string;
    FDuration: Integer;
    FShowCloseButton: Boolean;
    FLeadingIcon: TFRIconMode;
    FPosition: TFRMDSnackbarPosition;
    FSnackbarType: TFRMDSnackbarType;
    FOnAction: TNotifyEvent;
    FOnShow: TNotifyEvent;
    FOnHide: TNotifyEvent;
    FPanel: TCustomControl;
    FTimer: TTimer;
    FAnimTimer: TTimer;
    FAnimProgress: Single;
    FAnimClosing: Boolean;
    procedure OnTimerFire(Sender: TObject);
    procedure OnActionClick(Sender: TObject);
    procedure OnCloseClick(Sender: TObject);
    procedure DoAnimTick(Sender: TObject);
    procedure StartEntranceAnim;
    procedure StartExitAnim;
    function EaseOutCubic(T: Single): Single;
    function EaseInCubic(T: Single): Single;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Show; overload;
    procedure Show(const AMessage: string); overload;
    procedure Show(const AMessage, AAction: string); overload;
    procedure Show(const AMessage: string; AType: TFRMDSnackbarType); overload;
    procedure Show(const AMessage, AAction: string; AType: TFRMDSnackbarType); overload;
    procedure Hide;
    procedure ApplyTheme(const AThemeManager: TObject); virtual;
  published
    property Message: string read FMessage write FMessage;
    property ActionText: string read FActionText write FActionText;
    property Duration: Integer read FDuration write FDuration default 4000;
    property ShowCloseButton: Boolean read FShowCloseButton write FShowCloseButton default False;
    property LeadingIcon: TFRIconMode read FLeadingIcon write FLeadingIcon default imClear;
    property Position: TFRMDSnackbarPosition read FPosition write FPosition default spBottom;
    property SnackbarType: TFRMDSnackbarType read FSnackbarType write FSnackbarType default stDefault;
    property OnAction: TNotifyEvent read FOnAction write FOnAction;
    property OnShow: TNotifyEvent read FOnShow write FOnShow;
    property OnHide: TNotifyEvent read FOnHide write FOnHide;
  end;

procedure Register;

implementation

uses Math, StdCtrls, LCLType, LCLIntf;

{$IFDEF WINDOWS}
function CreateRoundRectRgn(X1, Y1, X2, Y2, W, H: Integer): HRGN;
  stdcall; external 'gdi32.dll';
function SetWindowRgn(hWnd: HWND; hRgn: HRGN; bRedraw: LongBool): Integer;
  stdcall; external 'user32.dll';
{$ENDIF}

const
  ANIM_DURATION = 250; { ms — MD3 standard duration }
  ANIM_INTERVAL = 16;  { ~60 fps }
  EXIT_DURATION = 200;  { ms — slightly faster exit }
  SNACKBAR_MARGIN = 24;       { margem lateral/vertical ao form }
  SNACKBAR_BOTTOM_MARGIN = 24; { distancia do fundo do form }
  SNACKBAR_MAX_WIDTH = 568;   { MD3 spec max width }
  SNACKBAR_MIN_WIDTH = 344;   { MD3 spec min width }
  SNACKBAR_PADDING_H = 20;
  SNACKBAR_PADDING_V = 14;
  SNACKBAR_MIN_H = 48;
  SNACKBAR_RADIUS = 16;       { pill-like MD3 corners }
  SHADOW_PAD     = 6;        { extra padding around body for shadow }
  ICON_SIZE = 24;
  CLOSE_BTN_SIZE = 24;
  ACTION_GAP = 12;

type
  TSnackbarPanel = class(TCustomControl)
  private
    FSnackbar: TFRMaterialSnackbar;
    FPaintCache: TBGRABitmap;
    FPaintCacheW: Integer;
    FPaintCacheH: Integer;
    FIconCache: TBGRABitmap;
    FCloseIconCache: TBGRABitmap;
    FAlpha: Byte;
    FDensityDelta: Integer;
    procedure InvalidatePaintCache;
    procedure GetTypeColors(out ABg, AText, AAction, AIconColor: TColor);
    function CalcContentHeight(AMaxTextW: Integer): Integer;
  protected
    function PaintCached(ABmp: TBGRABitmap): Boolean; virtual;
    procedure Paint; override;
    procedure EraseBackground({%H-}DC: HDC); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    destructor Destroy; override;
  end;

{ ── Color helpers ── }

procedure TSnackbarPanel.GetTypeColors(out ABg, AText, AAction, AIconColor: TColor);
begin
  case FSnackbar.FSnackbarType of
    stInfo:
    begin
      ABg := MD3Colors.PrimaryContainer;
      AText := MD3Colors.OnPrimaryContainer;
      AAction := MD3Colors.Primary;
      AIconColor := MD3Colors.Primary;
    end;
    stSuccess:
    begin
      ABg := MD3Colors.TertiaryContainer;
      AText := MD3Colors.OnTertiaryContainer;
      AAction := MD3Colors.Tertiary;
      AIconColor := MD3Colors.Tertiary;
    end;
    stWarning:
    begin
      ABg := MD3Colors.SecondaryContainer;
      AText := MD3Colors.OnSecondaryContainer;
      AAction := MD3Colors.Secondary;
      AIconColor := MD3Colors.Secondary;
    end;
    stError:
    begin
      ABg := MD3Colors.ErrorContainer;
      AText := MD3Colors.OnErrorContainer;
      AAction := MD3Colors.Error;
      AIconColor := MD3Colors.Error;
    end;
  else { stDefault }
    ABg := MD3Colors.InverseSurface;
    AText := MD3Colors.InverseOnSurface;
    AAction := MD3Colors.InversePrimary;
    AIconColor := MD3Colors.InverseOnSurface;
  end;
end;

function TSnackbarPanel.CalcContentHeight(AMaxTextW: Integer): Integer;
var
  R: TRect;
  flags: Cardinal;
  minH, padV: Integer;
begin
  minH := SNACKBAR_MIN_H + FDensityDelta;
  if minH < 32 then minH := 32;
  padV := SNACKBAR_PADDING_V + (FDensityDelta div 2);
  if padV < 6 then padV := 6;
  R := Rect(0, 0, AMaxTextW, 0);
  Canvas.Font.Size := 10;
  flags := DT_CALCRECT or DT_WORDBREAK or DT_LEFT;
  DrawText(Canvas.Handle, PChar(FSnackbar.FMessage), Length(FSnackbar.FMessage), R, flags);
  Result := Max(minH, R.Bottom - R.Top + padV * 2);
end;

destructor TSnackbarPanel.Destroy;
begin
  FreeAndNil(FPaintCache);
  FreeAndNil(FIconCache);
  FreeAndNil(FCloseIconCache);
  inherited Destroy;
end;

procedure TSnackbarPanel.InvalidatePaintCache;
begin
  FreeAndNil(FPaintCache);
  FPaintCacheW := 0;
  FPaintCacheH := 0;
end;

function TSnackbarPanel.PaintCached(ABmp: TBGRABitmap): Boolean;
var
  bgColor, txtColor, actColor, icoColor: TColor;
  textLeft, textRight: Integer;
  actionW, padV: Integer;
  aRect: TRect;
  ts: TTextStyle;
  hexColor: string;
begin
  Result := True;
  GetTypeColors(bgColor, txtColor, actColor, icoColor);

  { Pre-fill with parent bg for AA blending at corners }
  ABmp.Fill(ColorToBGRA(ColorToRGB(MD3Colors.Surface)));

  { Shadow — drawn within SHADOW_PAD area around the body }
  MD3DrawShadow(ABmp,
    SHADOW_PAD, SHADOW_PAD,
    Width - SHADOW_PAD, Height - SHADOW_PAD,
    SNACKBAR_RADIUS, elLevel3);

  { Body — anti-aliased rounded rect inside the shadow area }
  MD3FillRoundRect(ABmp,
    SHADOW_PAD - 0.5, SHADOW_PAD - 0.5,
    Width - SHADOW_PAD + 0.5, Height - SHADOW_PAD + 0.5,
    SNACKBAR_RADIUS, bgColor);

  { BGRA font setup — equivalent to Canvas.Font.Size := 10 }
  ABmp.FontHeight := -MulDiv(10, Screen.PixelsPerInch, 72);
  ABmp.FontQuality := fqFineClearTypeRGB;
  ABmp.FontStyle := [];

  textLeft := SHADOW_PAD + SNACKBAR_PADDING_H;
  textRight := Width - SHADOW_PAD - SNACKBAR_PADDING_H;

  { Leading icon — composited into the BGRA bitmap }
  if FSnackbar.FLeadingIcon <> imClear then
  begin
    hexColor := FRColorToSVGHex(icoColor);
    if FIconCache = nil then
      FIconCache := FRGetCachedIcon(FSnackbar.FLeadingIcon, hexColor, 2.0, ICON_SIZE, ICON_SIZE);
    if Assigned(FIconCache) then
      ABmp.PutImage(textLeft, (Height - ICON_SIZE) div 2, FIconCache, dmDrawWithTransparency);
    textLeft := textLeft + ICON_SIZE + 12;
  end;

  { Close button — antialiased X }
  if FSnackbar.FShowCloseButton then
  begin
    ABmp.DrawLineAntialias(
      textRight - CLOSE_BTN_SIZE + 6, (Height - CLOSE_BTN_SIZE) div 2 + 6,
      textRight - 6, (Height + CLOSE_BTN_SIZE) div 2 - 6,
      ColorToBGRA(ColorToRGB(txtColor)), 2.0);
    ABmp.DrawLineAntialias(
      textRight - 6, (Height - CLOSE_BTN_SIZE) div 2 + 6,
      textRight - CLOSE_BTN_SIZE + 6, (Height + CLOSE_BTN_SIZE) div 2 - 6,
      ColorToBGRA(ColorToRGB(txtColor)), 2.0);
    textRight := textRight - CLOSE_BTN_SIZE - ACTION_GAP;
  end;

  { Action text }
  if FSnackbar.FActionText <> '' then
  begin
    ABmp.FontStyle := [fsBold];
    actionW := ABmp.TextSize(FSnackbar.FActionText).cx + 24;
    aRect := Rect(textRight - actionW, SHADOW_PAD, textRight, Height - SHADOW_PAD);
    MD3DrawTextBGRA(ABmp, FSnackbar.FActionText, aRect, actColor,
      taRightJustify, True, True);
    ABmp.FontStyle := [];
    textRight := textRight - actionW - ACTION_GAP;
  end;

  { Message text }
  padV := SNACKBAR_PADDING_V + (FDensityDelta div 2);
  if padV < 6 then padV := 6;
  aRect := Rect(textLeft, SHADOW_PAD + padV, textRight, Height - SHADOW_PAD - padV);

  if Height > (SNACKBAR_MIN_H + FDensityDelta + SHADOW_PAD * 2) then
  begin
    { Multiline — word-wrapped BGRA text }
    FillChar(ts, SizeOf(ts), 0);
    ts.Wordbreak := True;
    ts.SingleLine := False;
    ts.Alignment := taLeftJustify;
    ts.Layout := tlTop;
    ts.Clipping := True;
    ABmp.TextRect(aRect, aRect.Left, aRect.Top, FSnackbar.FMessage, ts,
      ColorToBGRA(ColorToRGB(txtColor)));
  end
  else
    MD3DrawTextBGRA(ABmp, FSnackbar.FMessage, aRect, txtColor,
      taLeftJustify, True, True);
end;

procedure TSnackbarPanel.EraseBackground(DC: HDC);
var
  ARect: TRect;
begin
  if DC = 0 then Exit;
  ARect := Rect(0, 0, Width, Height);
  { Always use MD3Colors.Surface — the snackbar is parented to the Form
    whose Color may NOT be updated after dark-mode/palette toggles.
    MD3Colors.Surface is always in sync with the current scheme. }
  Brush.Color := MD3Colors.Surface;
  LCLIntf.FillRect(DC, ARect, HBRUSH(Brush.Reference.Handle));
end;

procedure TSnackbarPanel.Paint;
var
  bmp: TBGRABitmap;
begin
  if (Width <= 0) or (Height <= 0) then Exit;

  { Create/validate cached bitmap — full content (bg + text + icons) }
  if (FPaintCache = nil) or (FPaintCacheW <> Width) or (FPaintCacheH <> Height) then
  begin
    FreeAndNil(FPaintCache);
    FPaintCache := TBGRABitmap.Create(Width, Height, BGRAPixelTransparent);
    FPaintCacheW := Width;
    FPaintCacheH := Height;
    PaintCached(FPaintCache);
  end;

  { Single opaque blit — bitmap is pre-filled with Surface bg so
    corners are already correctly blended.  During fade animation
    (FAlpha < 255), duplicate + ApplyGlobalOpacity + alpha-blit. }
  if FAlpha < 255 then
  begin
    bmp := FPaintCache.Duplicate as TBGRABitmap;
    try
      bmp.ApplyGlobalOpacity(FAlpha);
      bmp.Draw(Canvas, 0, 0, False);
    finally
      bmp.Free;
    end;
  end
  else
    FPaintCache.Draw(Canvas, 0, 0, False);
end;

procedure TSnackbarPanel.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  bgColor, txtColor, actColor, icoColor: TColor;
  closeLeft, actionLeft, actionW: Integer;
begin
  inherited;
  if Button <> mbLeft then Exit;

  GetTypeColors(bgColor, txtColor, actColor, icoColor);

  { Check close button hit }
  closeLeft := Width - SHADOW_PAD - SNACKBAR_PADDING_H - CLOSE_BTN_SIZE;
  if FSnackbar.FShowCloseButton and (X >= closeLeft) then
  begin
    FSnackbar.OnCloseClick(Self);
    Exit;
  end;

  { Check action text hit }
  if FSnackbar.FActionText <> '' then
  begin
    Canvas.Font.Size := 10;
    actionW := Canvas.TextWidth(FSnackbar.FActionText) + 24;
    if FSnackbar.FShowCloseButton then
      actionLeft := closeLeft - ACTION_GAP - actionW
    else
      actionLeft := Width - SHADOW_PAD - SNACKBAR_PADDING_H - actionW;
    if X >= actionLeft then
      FSnackbar.OnActionClick(Self);
  end;
end;

{ ── TFRMaterialSnackbar ── }

constructor TFRMaterialSnackbar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMessage := '';
  FActionText := '';
  FDuration := 4000;
  FShowCloseButton := False;
  FLeadingIcon := imClear;
  FPosition := spBottom;
  FSnackbarType := stDefault;
  FPanel := nil;

  FTimer := TTimer.Create(Self);
  FTimer.Enabled := False;
  FTimer.OnTimer := @OnTimerFire;

  FAnimTimer := TTimer.Create(Self);
  FAnimTimer.Interval := ANIM_INTERVAL;
  FAnimTimer.Enabled := False;
  FAnimTimer.OnTimer := @DoAnimTick;

  FAnimProgress := 0;
  FAnimClosing := False;

  FRMDRegisterComponent(Self);
end;

destructor TFRMaterialSnackbar.Destroy;
begin
  FAnimTimer.Enabled := False;
  FTimer.Enabled := False;
  FreeAndNil(FPanel);
  FreeAndNil(FAnimTimer);
  FreeAndNil(FTimer);

  FRMDUnregisterComponent(Self);

  inherited Destroy;
end;

procedure TFRMaterialSnackbar.ApplyTheme(const AThemeManager: TObject);
begin
  if not Assigned(AThemeManager) then Exit;
  if Assigned(FPanel) then
  begin
    TSnackbarPanel(FPanel).InvalidatePaintCache;
    FreeAndNil(TSnackbarPanel(FPanel).FIconCache);
    FreeAndNil(TSnackbarPanel(FPanel).FCloseIconCache);
    FPanel.Invalidate;
  end;
end;

function TFRMaterialSnackbar.EaseOutCubic(T: Single): Single;
begin
  T := T - 1.0;
  Result := T * T * T + 1.0;
end;

function TFRMaterialSnackbar.EaseInCubic(T: Single): Single;
begin
  Result := T * T * T;
end;

procedure TFRMaterialSnackbar.DoAnimTick(Sender: TObject);
var
  step: Single;
  eased: Single;
  targetTop, startTop: Integer;
  ownerForm: TCustomForm;
  snkPanel: TSnackbarPanel;
begin
  if not Assigned(FPanel) then
  begin
    FAnimTimer.Enabled := False;
    Exit;
  end;

  snkPanel := TSnackbarPanel(FPanel);
  ownerForm := snkPanel.Parent as TCustomForm;

  if FAnimClosing then
  begin
    { Exit animation — fade out + slide away }
    step := ANIM_INTERVAL / EXIT_DURATION;
    FAnimProgress := FAnimProgress + step;
    if FAnimProgress >= 1.0 then
    begin
      FAnimProgress := 1.0;
      FAnimTimer.Enabled := False;
      { Desabilita o panel antes de liberar — garante que clicks/mouse
        events ja enfileirados nao sejam dispatched para memoria livre. }
      snkPanel.Enabled := False;
      snkPanel.Visible := False;
      FPanel := nil;
      snkPanel.Free;
      if Assigned(FOnHide) then
        FOnHide(Self);
      Exit;
    end;
    eased := EaseInCubic(FAnimProgress);
    snkPanel.FAlpha := EnsureRange(Round(255 * (1.0 - eased)), 0, 255);

    if FPosition = spBottom then
    begin
      startTop := ownerForm.ClientHeight - SNACKBAR_BOTTOM_MARGIN - snkPanel.Height;
      targetTop := ownerForm.ClientHeight;
      snkPanel.Top := startTop + Round((targetTop - startTop) * eased);
    end
    else
    begin
      startTop := SNACKBAR_MARGIN;
      targetTop := -snkPanel.Height;
      snkPanel.Top := startTop + Round((targetTop - startTop) * eased);
    end;
    snkPanel.Invalidate;
  end
  else
  begin
    { Entrance animation — slide in + fade in }
    step := ANIM_INTERVAL / ANIM_DURATION;
    FAnimProgress := FAnimProgress + step;
    if FAnimProgress >= 1.0 then
    begin
      FAnimProgress := 1.0;
      FAnimTimer.Enabled := False;
      { Start auto-hide timer }
      FTimer.Interval := FDuration;
      FTimer.Enabled := True;
      if Assigned(FOnShow) then
        FOnShow(Self);
    end;
    eased := EaseOutCubic(FAnimProgress);
    snkPanel.FAlpha := EnsureRange(Round(255 * eased), 0, 255);

    if FPosition = spBottom then
    begin
      startTop := ownerForm.ClientHeight;
      targetTop := ownerForm.ClientHeight - SNACKBAR_BOTTOM_MARGIN - snkPanel.Height;
      snkPanel.Top := startTop + Round((targetTop - startTop) * eased);
    end
    else
    begin
      startTop := -snkPanel.Height;
      targetTop := SNACKBAR_MARGIN;
      snkPanel.Top := startTop + Round((targetTop - startTop) * eased);
    end;
    snkPanel.Invalidate;
  end;
end;

procedure TFRMaterialSnackbar.StartEntranceAnim;
begin
  FAnimProgress := 0;
  FAnimClosing := False;
  FAnimTimer.Enabled := True;
end;

procedure TFRMaterialSnackbar.StartExitAnim;
begin
  FTimer.Enabled := False;
  FAnimProgress := 0;
  FAnimClosing := True;
  FAnimTimer.Enabled := True;
end;

procedure TFRMaterialSnackbar.Show;
var
  ownerForm: TCustomForm;
  snkPanel: TSnackbarPanel;
  panelW, panelH: Integer;
  maxTextW: Integer;
  tm: IFRMaterialThemeManager;
begin
  { If already showing, hide without animation first. Mesmo pattern do
    DoAnimTick: desabilita antes de free pra que mensagens na fila nao
    batam em memoria liberada. }
  if Assigned(FPanel) then
  begin
    FAnimTimer.Enabled := False;
    FTimer.Enabled := False;
    FPanel.Enabled := False;
    FPanel.Visible := False;
    snkPanel := TSnackbarPanel(FPanel);
    FPanel := nil;
    snkPanel.Free;
  end;

  ownerForm := nil;
  if Owner is TCustomForm then
    ownerForm := TCustomForm(Owner)
  else if (Owner is TControl) and Assigned(TControl(Owner).Parent) then
    ownerForm := GetParentForm(TControl(Owner));
  if ownerForm = nil then Exit;

  snkPanel := TSnackbarPanel.Create(ownerForm);
  snkPanel.ControlStyle := snkPanel.ControlStyle + [csOpaque];
  snkPanel.DoubleBuffered := True;
  snkPanel.FSnackbar := Self;
  snkPanel.FAlpha := 0;

  { Read density from ThemeManager for layout sizing }
  if Assigned(FRMaterialDefaultThemeManager) and
     Supports(FRMaterialDefaultThemeManager, IFRMaterialThemeManager, tm) then
    snkPanel.FDensityDelta := MD3DensityDelta(tm.Density)
  else
    snkPanel.FDensityDelta := 0;

  snkPanel.Parent := ownerForm;

  { Calculate width — clamp entre MIN_WIDTH e MAX_WIDTH, respeitando o
    espaco disponivel do form menos as margens laterais. MD3 spec: o
    snackbar ocupa no maximo 568dp horizontalmente em desktop, ficando
    centralizado ou end-aligned. Aqui centramos para preservar a
    simetria visual do showcase. }
  panelW := ownerForm.ClientWidth - SNACKBAR_MARGIN * 2;
  if panelW > SNACKBAR_MAX_WIDTH then
    panelW := SNACKBAR_MAX_WIDTH;
  if panelW < SNACKBAR_MIN_WIDTH then
    panelW := SNACKBAR_MIN_WIDTH;
  if panelW > ownerForm.ClientWidth - SNACKBAR_MARGIN * 2 then
    panelW := ownerForm.ClientWidth - SNACKBAR_MARGIN * 2;

  { Calculate available text width for multiline measurement }
  maxTextW := panelW - SNACKBAR_PADDING_H * 2;
  if FLeadingIcon <> imClear then
    maxTextW := maxTextW - ICON_SIZE - 12;
  if FShowCloseButton then
    maxTextW := maxTextW - CLOSE_BTN_SIZE - ACTION_GAP;
  if FActionText <> '' then
  begin
    snkPanel.Canvas.Font.Size := 10;
    maxTextW := maxTextW - snkPanel.Canvas.TextWidth(FActionText) - 24 - ACTION_GAP;
  end;

  { Calculate height based on text }
  panelH := snkPanel.CalcContentHeight(maxTextW);

  snkPanel.Width := panelW + SHADOW_PAD * 2;
  snkPanel.Height := panelH + SHADOW_PAD * 2;
  { Centraliza horizontalmente respeitando a margem lateral. Se o form
    for menor que MIN_WIDTH + margens, o clamp acima ja cortou o
    panelW — aqui so posicionamos. }
  snkPanel.Left := (ownerForm.ClientWidth - panelW) div 2 - SHADOW_PAD;

  { Start off-screen for animation — alem do rect visivel mais o
    SNACKBAR_BOTTOM_MARGIN, para a slide-up animation terminar com
    margem bonita do fundo. }
  if FPosition = spBottom then
    snkPanel.Top := ownerForm.ClientHeight  { below screen }
  else
    snkPanel.Top := -panelH;  { above screen }

  { Anchors sem akLeft/akRight: a gente nao quer o snackbar esticar
    quando o form redimensiona. Fixa largura, re-centra no proximo
    Show. }
  snkPanel.Anchors := [akBottom];
  snkPanel.BringToFront;

  { Clip the panel to a rounded rectangle — the OS handles transparency
    at corners, so the snackbar floats cleanly over any background. }
  { No region clipping — shadow needs to extend beyond the rounded body.
    The BGRA pre-fill with Surface color handles the AA blending. }

  FPanel := snkPanel;
  FPanel.FreeNotification(Self);

  { Start entrance animation }
  StartEntranceAnim;
end;

procedure TFRMaterialSnackbar.Show(const AMessage: string);
begin
  FMessage := AMessage;
  Show;
end;

procedure TFRMaterialSnackbar.Show(const AMessage, AAction: string);
begin
  FMessage := AMessage;
  FActionText := AAction;
  Show;
end;

procedure TFRMaterialSnackbar.Show(const AMessage: string; AType: TFRMDSnackbarType);
begin
  FMessage := AMessage;
  FSnackbarType := AType;
  Show;
end;

procedure TFRMaterialSnackbar.Show(const AMessage, AAction: string; AType: TFRMDSnackbarType);
begin
  FMessage := AMessage;
  FActionText := AAction;
  FSnackbarType := AType;
  Show;
end;

procedure TFRMaterialSnackbar.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent = FPanel) then
    FPanel := nil;
end;

procedure TFRMaterialSnackbar.Hide;
begin
  if Assigned(FPanel) and not FAnimClosing then
    StartExitAnim
  else if Assigned(FPanel) then
  begin
    { Force hide if already animating out }
    FAnimTimer.Enabled := False;
    FTimer.Enabled := False;
    FreeAndNil(FPanel);
    if Assigned(FOnHide) then
      FOnHide(Self);
  end;
end;

procedure TFRMaterialSnackbar.OnTimerFire(Sender: TObject);
begin
  FTimer.Enabled := False;
  Hide;
end;

procedure TFRMaterialSnackbar.OnActionClick(Sender: TObject);
begin
  if Assigned(FOnAction) then
    FOnAction(Self);
  Hide;
end;

procedure TFRMaterialSnackbar.OnCloseClick(Sender: TObject);
begin
  Hide;
end;

procedure Register;
begin
  {$IFDEF FPC}
    {$I icons\frmaterialsnackbar_icon.lrs}
  {$ENDIF}
  RegisterComponents('Material Design 3', [TFRMaterialSnackbar]);
end;

end.
