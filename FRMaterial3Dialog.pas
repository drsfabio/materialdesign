unit FRMaterial3Dialog;

{$mode objfpc}{$H+}

{ Material Design 3 — Dialog.

  TFRMaterialDialog — Modal dialog component with full MD3 styling.
  Non-visual component; call Execute to show.

  Features:
  - Fade-in scrim + scale-up card animation (MD3 motion spec)
  - Dismiss via Escape or scrim click (configurable)
  - Responsive width (scales to screen, min 280 max 560)
  - Scrollable content for long text
  - i18n-ready button captions
  - Custom icon support via TFRIconMode
  - Full theme integration (ApplyTheme updates live dialog)
  - Tab navigation between buttons (accessibility)
  - High-DPI aware layout

  License: LGPL v3
}

interface

uses
  Classes, SysUtils, Controls, Graphics, Forms, StdCtrls, ExtCtrls,
  LCLIntf, LCLType, LMessages, Math, Dialogs,
  {$IFDEF FPC} LResources, {$ENDIF}
  BGRABitmap, BGRABitmapTypes, FRMaterialTheme, FRMaterial3Base, FRMaterial3Button,
  FRMaterialIcons, FRMaterial3TitleBar;

type
  TFRMDDialogButton = (dbNone, dbOK, dbCancel, dbYes, dbNo, dbClose);
  TFRMDDialogButtons = set of TFRMDDialogButton;
  TFRMDDialogResult = (drNone, drOK, drCancel, drYes, drNo, drClose);
  TFRMDDialogIcon = (diNone, diInfo, diWarning, diError, diSuccess, diHelp, diCustom);

  { ── TFRMaterialDialog ── }

  TFRMaterialDialog = class(TComponent, IFRMaterialComponent)
  private
    FTitle: string;
    FContent: string;
    FButtons: TFRMDDialogButtons;
    FDialogIcon: TFRMDDialogIcon;
    FCustomIcon: TFRIconMode;
    FDismissOnScrim: Boolean;
    FDismissOnEscape: Boolean;
    FScrimOpacity: Byte;
    FCaptionOK: string;
    FCaptionCancel: string;
    FCaptionYes: string;
    FCaptionNo: string;
    FCaptionClose: string;
    FMaxContentHeight: Integer;
    FIconSize: Integer;
    FIconAlignment: TAlignment;
    procedure SetTitle(const AValue: string);
    procedure SetContent(const AValue: string);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Execute: TFRMDDialogResult;
    procedure ApplyTheme(const AThemeManager: TObject); virtual;
  published
    property Title: string read FTitle write SetTitle;
    property Content: string read FContent write SetContent;
    property Buttons: TFRMDDialogButtons read FButtons write FButtons default [dbOK, dbCancel];
    property DialogIcon: TFRMDDialogIcon read FDialogIcon write FDialogIcon default diNone;
    property CustomIcon: TFRIconMode read FCustomIcon write FCustomIcon default imInfo;
    property DismissOnScrim: Boolean read FDismissOnScrim write FDismissOnScrim default True;
    property DismissOnEscape: Boolean read FDismissOnEscape write FDismissOnEscape default True;
    { Scrim opacity: 0=fully transparent, 255=fully opaque. Default 128 (50%) per MD3 spec }
    property ScrimOpacity: Byte read FScrimOpacity write FScrimOpacity default 128;
    property CaptionOK: string read FCaptionOK write FCaptionOK;
    property CaptionCancel: string read FCaptionCancel write FCaptionCancel;
    property CaptionYes: string read FCaptionYes write FCaptionYes;
    property CaptionNo: string read FCaptionNo write FCaptionNo;
    property CaptionClose: string read FCaptionClose write FCaptionClose;
    { Max height for content area before scroll kicks in (0 = auto) }
    property MaxContentHeight: Integer read FMaxContentHeight write FMaxContentHeight default 0;
    { Tamanho em pixels do icone do dialog (diWarning/diInfo/etc). MD3 spec:
      24 (small), 48 (medium), 64 (large). Range 16..96. }
    property IconSize: Integer read FIconSize write FIconSize default 48;
    { Alinhamento horizontal do icone no card do dialog.
      taLeftJustify: icone a esquerda do conteudo (padrao MD3 headline).
      taCenter: icone centralizado acima do conteudo (notificacao).
      taRightJustify: icone a direita. }
    property IconAlignment: TAlignment read FIconAlignment write FIconAlignment default taCenter;
  end;

{ Global helper — substitui MessageDlg com visual MD3 }
function MessageDialog(const ATitle, AContent: string;
  AIcon: TFRMDDialogIcon; AButtons: TFRMDDialogButtons): TFRMDDialogResult;

{ Drop-in wrappers — mesma assinatura do Dialogs.MessageDlg / ShowMessage }
function MD3MessageDlg(const ATitle, AContent: string; AType: TMsgDlgType;
  AButtons: TMsgDlgButtons; AHelpCtx: Longint): TModalResult;
procedure MD3ShowMessage(const AMsg: string);

procedure Register;

implementation

{$IFDEF WINDOWS}
function CreateRoundRectRgn(X1, Y1, X2, Y2, W, H: Integer): HRGN;
  stdcall; external 'gdi32.dll';
function SetWindowRgn(hWnd: HWND; hRgn: HRGN; bRedraw: LongBool): Integer;
  stdcall; external 'user32.dll';
{$ENDIF}

const
  PADDING             = 24;
  BTN_H               = 40;
  BTN_GAP             = 8;
  TITLE_GAP           = 16;
  CONTENT_GAP         = 24;
  ICON_SIZE           = 24;
  ICON_GAP            = 16;
  DLG_MIN_W           = 280;
  DLG_MAX_W           = 560;
  DLG_PREF_W          = 420;
  ANIM_DURATION       = 200; { ms }
  ANIM_INTERVAL       = 16;  { ~60 fps }
  CORNER_RADIUS       = 28;  { MD3 extra-large shape }
  MAX_CONTENT_DEFAULT = 320; { max content height before scroll }
  TITLEBAR_H          = 48;  { Altura do TFRMaterialTitleBar no topo do dialog — spec MD3 }

type
  { ── Internal scrim + dialog form ── }

  TFRDialogPanel = class(TCustomControl)
  private
    FPaintCache: TBGRABitmap;
    FIconBmp: TBGRABitmap;
    FIconLeft: Integer;
    FIconTop: Integer;
    FScrimAlpha: Byte;
    procedure InvalidateCache;
  protected
    procedure Paint; override;
    procedure WMEraseBkgnd(var Msg: TLMEraseBkgnd); message LM_ERASEBKGND;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

  TFRDialogForm = class(TFRMaterialForm)
  private
    FResult: TFRMDDialogResult;
    FDialogPanel: TFRDialogPanel;
    FDefaultBtn: TFRMaterialButton;
    FDismissOnScrim: Boolean;
    FDismissOnEscape: Boolean;
    FScrimOpacity: Byte;  { mantido por compat API — sem efeito visual (janela modal tradicional) }
    FLblContent: TLabel;
    FScrollBox: TScrollBox;
    FBtnList: TFPList;
    { Animation state — scale-up simples do card }
    FAnimTimer: TTimer;
    FAnimProgress: Single; { 0..1 }
    FAnimating: Boolean;
    FTargetPanelLeft: Integer;
    FTargetPanelTop: Integer;
    procedure BtnClick(Sender: TObject);
    procedure DialogShow(Sender: TObject);
    procedure DoAnimTick(Sender: TObject);
    procedure StartAnimation;
    function EaseOutCubic(T: Single): Single;
  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    constructor CreateDialog(ATitle, AContent: string;
      AButtons: TFRMDDialogButtons; AIcon: TFRMDDialogIcon;
      ACustomIcon: TFRIconMode; ADismissOnScrim, ADismissOnEscape: Boolean;
      const ACaptionOK, ACaptionCancel, ACaptionYes, ACaptionNo, ACaptionClose: string;
      AMaxContentH: Integer; AScrimOpacity: Byte;
      AIconSize: Integer; AIconAlignment: TAlignment);
    destructor Destroy; override;
  end;

{ ── TFRDialogPanel — rounded card with cache ── }

constructor TFRDialogPanel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  { csOpaque: we paint every pixel ourselves — prevents LCL from filling
    a solid Color rectangle that would hide the rounded corners. }
  ControlStyle := ControlStyle + [csOpaque];
end;

procedure TFRDialogPanel.WMEraseBkgnd(var Msg: TLMEraseBkgnd);
begin
  { Block LCL from painting the background — we handle it entirely in Paint }
  Msg.Result := 1;
end;

procedure TFRDialogPanel.InvalidateCache;
begin
  FreeAndNil(FPaintCache);
end;

procedure TFRDialogPanel.Paint;
begin
  if (Width <= 0) or (Height <= 0) then Exit;

  if FPaintCache = nil then
  begin
    { Fundo opaco da cor do card + icon MD3 (se houver).
      Cantos arredondados e shadow sao responsabilidade do TFRMaterialForm
      via DWM (Windows). Sem scrim/backdrop — janela modal tradicional. }
    FPaintCache := TBGRABitmap.Create(Width, Height,
      ColorToBGRA(MD3Colors.SurfaceContainerHigh));

    if Assigned(FIconBmp) then
      FPaintCache.PutImage(FIconLeft, FIconTop, FIconBmp, dmDrawWithTransparency);
  end;

  FPaintCache.Draw(Canvas, 0, 0, False);
end;

destructor TFRDialogPanel.Destroy;
begin
  FreeAndNil(FPaintCache);
  FreeAndNil(FIconBmp);
  inherited Destroy;
end;

{ ── TFRDialogForm ── }

function TFRDialogForm.EaseOutCubic(T: Single): Single;
begin
  T := T - 1.0;
  Result := T * T * T + 1.0;
end;

procedure TFRDialogForm.DoAnimTick(Sender: TObject);
begin
  { Animacao removida — janela modal tradicional sem scale-up.
    Foca o botao default imediatamente. }
  FAnimating := False;
  if Assigned(FAnimTimer) then
    FAnimTimer.Enabled := False;
  if Assigned(FDefaultBtn) and FDefaultBtn.Visible and FDefaultBtn.Enabled then
    ActiveControl := FDefaultBtn;
end;

procedure TFRDialogForm.StartAnimation;
begin
  FAnimating := False;
  FAnimProgress := 1.0;
  { Dispara um tick imediato para focar botao default — sem animacao visual. }
  FAnimTimer := TTimer.Create(Self);
  FAnimTimer.Interval := 1;
  FAnimTimer.OnTimer := @DoAnimTick;
  FAnimTimer.Enabled := True;
end;

constructor TFRDialogForm.CreateDialog(ATitle, AContent: string;
  AButtons: TFRMDDialogButtons; AIcon: TFRMDDialogIcon;
  ACustomIcon: TFRIconMode; ADismissOnScrim, ADismissOnEscape: Boolean;
  const ACaptionOK, ACaptionCancel, ACaptionYes, ACaptionNo, ACaptionClose: string;
  AMaxContentH: Integer; AScrimOpacity: Byte;
  AIconSize: Integer; AIconAlignment: TAlignment);
var
  btn: TFRMaterialButton;
  btnX, titleH, contentH, contentTop, dlgHeight, curY: Integer;
  dlgWidth, maxContentH: Integer;
  R: TRect;
  iconMode: TFRIconMode;
  hexColor: string;
  themeFontName: string;

  procedure AddBtn(ABtnType: TFRMDDialogButton; const ACaption: string;
    AStyle: TFRMDButtonStyle);
  begin
    btn := TFRMaterialButton.Create(Self);
    btn.Parent := FDialogPanel;
    btn.Caption := ACaption;
    btn.Tag := Ord(ABtnType);
    btn.OnClick := @BtnClick;
    btn.ButtonStyle := AStyle;
    btn.Height := BTN_H;
    btn.TabStop := True;
    Canvas.Font.Name := themeFontName;
    Canvas.Font.Size := 10;
    btn.Width := Canvas.TextWidth(ACaption) + 48;
    if btn.Width < 90 then btn.Width := 90;
    btnX := btnX - btn.Width - BTN_GAP;
    btn.Left := btnX + BTN_GAP;
    btn.Top := dlgHeight - PADDING - BTN_H;
    btn.Anchors := [akRight, akBottom];
    if (AStyle = mbsFilled) and (FDefaultBtn = nil) then
      FDefaultBtn := btn;
    FBtnList.Add(btn);
  end;

begin
  inherited CreateNew(nil);
  { Default drCancel — garante que fechar por TitleBar X, Escape, scrim,
    ALT+F4 ou qualquer outro meio retorne resultado semanticamente "cancelado". }
  FResult := drCancel;
  FDefaultBtn := nil;
  FDismissOnScrim := ADismissOnScrim;
  FDismissOnEscape := ADismissOnEscape;
  FScrimOpacity := AScrimOpacity;
  FBtnList := TFPList.Create;
  FAnimTimer := nil;

  { Form modal tradicional — SEM scrim fullscreen.
    bsNone mantido para que cantos arredondados do card sejam visiveis
    sem moldura nativa. Position poScreenCenter centraliza na tela. }
  BorderStyle := bsNone;
  Position := poScreenCenter;
  Color := MD3Colors.SurfaceContainerHigh;
  KeyPreview := True;
  OnShow := @DialogShow;

  { Theme font — use system font from theme, fallback to Segoe UI }
  themeFontName := Screen.SystemFont.Name;
  if themeFontName = '' then themeFontName := 'Segoe UI';

  Font.Name := themeFontName;
  Font.Quality := fqClearTypeNatural;

  { Responsive width }
  dlgWidth := DLG_PREF_W;
  if Screen.Width > 0 then
  begin
    if dlgWidth > Screen.Width - 64 then
      dlgWidth := Screen.Width - 64;
  end;
  dlgWidth := EnsureRange(dlgWidth, DLG_MIN_W, DLG_MAX_W);

  { Starting Y position — TitleBar eh do form pai (TFRMaterialForm),
    FDialogPanel soh contem o corpo do dialog. }
  curY := PADDING;

  { If icon requested AND centered above content, reserve vertical space.
    Se alinhado a esquerda/direita, o icone fica lateral ao texto (sem gap vertical). }
  if (AIcon <> diNone) and (AIconAlignment = taCenter) then
    curY := curY + AIconSize + ICON_GAP;

  { Title eh renderizado no TFRMaterialTitleBar — no corpo do dialog nao ha
    mais FLblTitle separado. titleH=0 remove o gap extra. }
  titleH := 0;

  { Measure content text height with word-wrap }
  Canvas.Font.Name := themeFontName;
  Canvas.Font.Size := 10;
  Canvas.Font.Style := [];
  R := Rect(0, 0, dlgWidth - PADDING * 2, 0);
  DrawText(Canvas.Handle, PChar(AContent), Length(AContent), R,
    DT_CALCRECT or DT_WORDBREAK or DT_NOPREFIX);
  contentH := R.Bottom - R.Top;
  if contentH < Canvas.TextHeight('Tg') then
    contentH := Canvas.TextHeight('Tg');

  { Max content height — enable scroll if exceeded }
  maxContentH := AMaxContentH;
  if maxContentH <= 0 then
    maxContentH := MAX_CONTENT_DEFAULT;

  { Calculate dialog height — sem TITLE_GAP (title migrou para o TitleBar) }
  contentTop := curY;
  dlgHeight := contentTop + Min(contentH + 4, maxContentH) + CONTENT_GAP + BTN_H + PADDING;
  if dlgHeight < 180 then dlgHeight := 180;

  { Form tem exatamente o tamanho do card + TitleBar — sem scrim fullscreen.
    TFRMaterialForm ja criou TitleBar no topo automaticamente. }
  Self.ClientWidth  := dlgWidth;
  Self.ClientHeight := dlgHeight + TITLEBAR_H;

  { Dialog content panel — alClient preenche area abaixo da TitleBar do pai }
  FDialogPanel := TFRDialogPanel.Create(Self);
  FDialogPanel.Parent := Self;
  FDialogPanel.Align := alClient;
  FDialogPanel.Tag := dlgHeight;
  FDialogPanel.FScrimAlpha := 0;
  FDialogPanel.Color := MD3Colors.SurfaceContainerHigh;

  { TitleBar MD3 do TFRMaterialForm — apenas botao Close (X).
    Clique no X chama frm.Close → FResult ja inicializado como drCancel retorna. }
  if Assigned(TitleBar) then
  begin
    TitleBar.Height := TITLEBAR_H;
    TitleBar.Buttons := [tbbClose];
    TitleBar.Title := ATitle;
  end;

  { Icon — rendered directly on the panel's BGRABitmap, abaixo do TitleBar }
  if AIcon <> diNone then
  begin
    case AIcon of
      diWarning: iconMode := imWarning;
      diInfo:    iconMode := imInfo;
      diError:   iconMode := imError;
      diSuccess: iconMode := imSuccess;
      diHelp:    iconMode := imHelp;
      diCustom:  iconMode := ACustomIcon;
    else
      iconMode := imInfo;
    end;
    hexColor := FRColorToSVGHex(MD3Colors.Primary);
    FDialogPanel.FIconBmp := FRRenderSVGIcon(
      FRGetIconSVG(iconMode, hexColor, 2.0), AIconSize, AIconSize);
    case AIconAlignment of
      taLeftJustify:  FDialogPanel.FIconLeft := PADDING;
      taRightJustify: FDialogPanel.FIconLeft := dlgWidth - AIconSize - PADDING;
    else { taCenter }
      FDialogPanel.FIconLeft := (dlgWidth - AIconSize) div 2;
    end;
    FDialogPanel.FIconTop := PADDING;
  end;

  { Content — scrollable if exceeds max height }
  if contentH + 4 > maxContentH then
  begin
    FScrollBox := TScrollBox.Create(Self);
    FScrollBox.Parent := FDialogPanel;
    FScrollBox.Left := PADDING;
    FScrollBox.Top := contentTop;
    FScrollBox.Width := dlgWidth - PADDING * 2;
    FScrollBox.Height := maxContentH;
    FScrollBox.BorderStyle := bsNone;
    FScrollBox.Color := MD3Colors.SurfaceContainerHigh;
    FScrollBox.HorzScrollBar.Visible := False;
    FScrollBox.VertScrollBar.Smooth := True;
    FScrollBox.VertScrollBar.Tracking := True;
    FScrollBox.Anchors := [akLeft, akTop, akRight];

    FLblContent := TLabel.Create(Self);
    FLblContent.Parent := FScrollBox;
    FLblContent.Left := 0;
    FLblContent.Top := 0;
    FLblContent.AutoSize := False;
    FLblContent.Width := FScrollBox.ClientWidth - 16; { scrollbar space }
    FLblContent.Height := contentH + 4;
    FLblContent.WordWrap := True;
    FLblContent.Caption := AContent;
    FLblContent.Transparent := True;
    FLblContent.ParentFont := False;
    FLblContent.Font.Name := themeFontName;
    FLblContent.Font.Size := 10;
    FLblContent.Font.Style := [];
    FLblContent.Font.Color := MD3Colors.OnSurfaceVariant;
  end
  else
  begin
    FScrollBox := nil;
    FLblContent := TLabel.Create(Self);
    FLblContent.Parent := FDialogPanel;
    FLblContent.Left := PADDING;
    FLblContent.Top := contentTop;
    FLblContent.AutoSize := False;
    FLblContent.Width := dlgWidth - PADDING * 2;
    FLblContent.Height := contentH + 4;
    FLblContent.WordWrap := True;
    FLblContent.Caption := AContent;
    FLblContent.Transparent := True;
    FLblContent.ParentFont := False;
    FLblContent.Font.Name := themeFontName;
    FLblContent.Font.Size := 10;
    FLblContent.Font.Style := [];
    FLblContent.Font.Color := MD3Colors.OnSurfaceVariant;
  end;

  { Buttons — right-aligned, confirm on right }
  btnX := dlgWidth - PADDING;

  if dbOK in AButtons then
    AddBtn(dbOK, ACaptionOK, mbsFilled);
  if dbYes in AButtons then
    AddBtn(dbYes, ACaptionYes, mbsFilled);
  if dbClose in AButtons then
    AddBtn(dbClose, ACaptionClose, mbsText);
  if dbNo in AButtons then
    AddBtn(dbNo, ACaptionNo, mbsOutlined);
  if dbCancel in AButtons then
    AddBtn(dbCancel, ACaptionCancel, mbsText);
end;

destructor TFRDialogForm.Destroy;
begin
  FreeAndNil(FBtnList);
  inherited Destroy;
end;

procedure TFRDialogForm.DialogShow(Sender: TObject);
{$IFDEF WINDOWS}
var R: Integer;
{$ENDIF}
begin
  {$IFDEF WINDOWS}
  { SetWindowRgn com radius CORNER_RADIUS — recorta o form na forma
    arredondada EXATA do card. Sem isso, o DWM shadow sozinho deixa
    pixels brancos/cinza visiveis nos cantos externos (diferenca entre
    a borda retangular do form e os cantos arredondados do card).
    Pixel-perfect expansion de 1px preserva anti-aliasing BGRA na borda. }
  if HandleAllocated then
  begin
    R := CORNER_RADIUS;
    SetWindowRgn(Handle,
      CreateRoundRectRgn(-1, -1, Width + 2, Height + 2, R * 2 + 2, R * 2 + 2),
      True);
  end;
  {$ENDIF}
  StartAnimation;
end;

procedure TFRDialogForm.Paint;
begin
  { Sem pintura custom no form — TFRMaterialForm ja cuida de borda/shadow.
    FDialogPanel (alClient) pinta o corpo. }
  inherited Paint;
end;

procedure TFRDialogForm.Resize;
begin
  inherited Resize;
  { FDialogPanel = alClient, ajusta-se automaticamente ao resize.
    InvalidateCache para refazer pintura com o novo tamanho. }
  if Assigned(FDialogPanel) then
    FDialogPanel.InvalidateCache;
end;

procedure TFRDialogForm.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  if (Key = VK_ESCAPE) and FDismissOnEscape then
  begin
    FResult := drCancel;
    ModalResult := mrCancel;
  end;
end;

procedure TFRDialogForm.BtnClick(Sender: TObject);
begin
  case TFRMDDialogButton(TControl(Sender).Tag) of
    dbOK:     FResult := drOK;
    dbCancel: FResult := drCancel;
    dbYes:    FResult := drYes;
    dbNo:     FResult := drNo;
    dbClose:  FResult := drClose;
  end;
  ModalResult := mrOk;
end;

{ ── TFRMaterialDialog ── }

constructor TFRMaterialDialog.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTitle           := 'Título';
  FContent         := 'Conteúdo da mensagem.';
  FButtons         := [dbOK, dbCancel];
  FDialogIcon      := diNone;
  FCustomIcon      := imInfo;
  FDismissOnScrim  := True;
  FDismissOnEscape := True;
  FCaptionOK       := 'OK';
  FCaptionCancel   := 'Cancelar';
  FCaptionYes      := 'Sim';
  FCaptionNo       := 'Não';
  FCaptionClose    := 'Fechar';
  FScrimOpacity    := 128;
  FMaxContentHeight := 0;
  FIconSize        := 48;
  FIconAlignment   := taCenter;

  FRMDRegisterComponent(Self);
end;

destructor TFRMaterialDialog.Destroy;
begin
  FRMDUnregisterComponent(Self);
  inherited Destroy;
end;

procedure TFRMaterialDialog.ApplyTheme(const AThemeManager: TObject);
var
  i: Integer;
  frm: TFRDialogForm;
begin
  if not Assigned(AThemeManager) then Exit;
  { Update any currently showing dialog }
  for i := 0 to Screen.FormCount - 1 do
    if Screen.Forms[i] is TFRDialogForm then
    begin
      frm := TFRDialogForm(Screen.Forms[i]);
      { Update label colors — TitleBar sincroniza via SyncWithTheme proprio }
      if Assigned(frm.FLblContent) then
        frm.FLblContent.Font.Color := MD3Colors.OnSurfaceVariant;
      { Update panel background }
      if Assigned(frm.FDialogPanel) then
      begin
        frm.FDialogPanel.Color := MD3Colors.SurfaceContainerHigh;
        frm.FDialogPanel.InvalidateCache;
        frm.FDialogPanel.Invalidate;
      end;
      { Scrollbox background }
      if Assigned(frm.FScrollBox) then
        frm.FScrollBox.Color := MD3Colors.SurfaceContainerHigh;
      frm.Invalidate;
    end;
end;

procedure TFRMaterialDialog.SetTitle(const AValue: string);
begin
  FTitle := AValue;
end;

procedure TFRMaterialDialog.SetContent(const AValue: string);
begin
  FContent := AValue;
end;

function TFRMaterialDialog.Execute: TFRMDDialogResult;
var
  dlg: TFRDialogForm;
begin
  dlg := TFRDialogForm.CreateDialog(FTitle, FContent, FButtons, FDialogIcon,
    FCustomIcon, FDismissOnScrim, FDismissOnEscape,
    FCaptionOK, FCaptionCancel, FCaptionYes, FCaptionNo, FCaptionClose,
    FMaxContentHeight, FScrimOpacity, FIconSize, FIconAlignment);
  try
    dlg.ShowModal;
    Result := dlg.FResult;
  finally
    dlg.Free;
  end;
end;

procedure Register;
begin
  {$IFDEF FPC}
    {$I icons\frmaterialdialog_icon.lrs}
  {$ENDIF}
  RegisterComponents('Material Design 3', [TFRMaterialDialog]);
end;

function MessageDialog(const ATitle, AContent: string;
  AIcon: TFRMDDialogIcon; AButtons: TFRMDDialogButtons): TFRMDDialogResult;
begin
  with TFRMaterialDialog.Create(nil) do
  try
    Title      := ATitle;
    Content    := AContent;
    DialogIcon := AIcon;
    Buttons    := AButtons;
    Result     := Execute;
  finally
    Free;
  end;
end;

{ ── Drop-in wrappers ── }

function MsgDlgTypeToIcon(AType: TMsgDlgType): TFRMDDialogIcon;
begin
  case AType of
    mtWarning:      Result := diWarning;
    mtError:        Result := diError;
    mtInformation:  Result := diInfo;
    mtConfirmation: Result := diInfo;
    mtCustom:       Result := diNone;
  else
    Result := diNone;
  end;
end;

function MsgDlgBtnsToMD3(ABtns: TMsgDlgButtons): TFRMDDialogButtons;
begin
  Result := [];
  if mbOK in ABtns      then Include(Result, dbOK);
  if mbCancel in ABtns   then Include(Result, dbCancel);
  if mbYes in ABtns      then Include(Result, dbYes);
  if mbNo in ABtns       then Include(Result, dbNo);
  if mbClose in ABtns    then Include(Result, dbClose);
end;

function MD3ResultToModalResult(AResult: TFRMDDialogResult): TModalResult;
begin
  case AResult of
    drOK:     Result := mrOK;
    drCancel: Result := mrCancel;
    drYes:    Result := mrYes;
    drNo:     Result := mrNo;
    drClose:  Result := mrClose;
  else
    Result := mrNone;
  end;
end;

function MD3MessageDlg(const ATitle, AContent: string; AType: TMsgDlgType;
  AButtons: TMsgDlgButtons; AHelpCtx: Longint): TModalResult;
var
  DR: TFRMDDialogResult;
begin
  DR := MessageDialog(ATitle, AContent,
          MsgDlgTypeToIcon(AType),
          MsgDlgBtnsToMD3(AButtons));
  Result := MD3ResultToModalResult(DR);
end;

procedure MD3ShowMessage(const AMsg: string);
begin
  MessageDialog('', AMsg, diNone, [dbOK]);
end;

end.
