unit FRMaterial3Combo;

{$mode objfpc}{$H+}

{ Material Design 3 — Custom Combobox.

  TFRMaterialCombo — select de itens 100% custom, sem TComboBox nativo
    do LCL. O controle principal eh um TFRMaterial3Control que pinta
    com BGRA: outline/filled, label flutuante, texto do item atual e
    triangulo de dropdown. O popup eh um TCustomForm stayOnTop que
    hospeda um painel custom para cada item no estilo Material Select:

      - Item normal: texto OnSurface, sem background
      - Item hovered: state-layer sutil (hover overlay)
      - Item selecionado: pill SecondaryContainer + checkmark + texto
        OnSecondaryContainer (look "filled tonal button")

  Sem heranca de legado. Sem dependencia de TComboBox, TListBox ou
  TEdit. Tudo pintado via BGRA seguindo os tokens MD3.

  Licenca: LGPL v3
}

interface

uses
  Classes, SysUtils, Controls, Graphics, Forms, ExtCtrls,
  {$IFDEF FPC} LCLType, LCLIntf, LResources, {$ENDIF}
  BGRABitmap, BGRABitmapTypes,
  FRMaterialTheme, FRMaterial3Base, FRMaterialIcons;

type
  TFRMaterialCombo = class;

  { TFRMDComboPopup — TForm stayOnTop que pinta os itens do Combo }

  TFRMDComboPopupCallback = procedure(AIndex: Integer) of object;

  { TFRMDComboPopup — hospeda a lista filtrada. Recebe a densidade
    do combo pai para ajustar altura do item e do search field. }

  TFRMDComboPopup = class(TCustomForm)
  private
    FItems: TStrings;
    FItemIndex: Integer;
    FOnSelect: TFRMDComboPopupCallback;
    FClosing: Boolean;
    FItemHeight: Integer;
    FPadding: Integer;
    FRadius: Integer;
    { Search + virtualizacao }
    FFilterText: string;
    FFilteredIndices: array of Integer;
    FFilteredCount: Integer;
    FTopIndex: Integer;
    FCursorIndex: Integer;      { posicao no espaco filtrado, nao no original }
    FListAreaTop: Integer;      { y onde comeca a area de itens (abaixo do search) }
    FListAreaHeight: Integer;   { altura da area de lista em pixels }
    FVisibleCount: Integer;     { quantos itens cabem simultaneamente na lista }
    FFontHeight: Integer;       { BGRA FontHeight calculado a partir do Font.Size do combo }
    { Caret blink }
    FCaretTimer: TTimer;
    FCaretVisible: Boolean;
    procedure DoCaretTick(Sender: TObject);
    procedure PaintPopup;
    function ItemAtY(AY: Integer): Integer;   { retorna indice filtrado, -1 se fora }
    procedure RebuildFilter;
    procedure EnsureCursorVisible;
    procedure PickCurrent;
    function PrintableChar(Key: Word; Shift: TShiftState): Char;
  protected
    procedure Paint; override;
    procedure EraseBackground({%H-}DC: HDC); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseLeave; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure UTF8KeyPress(var UTF8Key: TUTF8Char); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
      MousePos: TPoint): Boolean; override;
    procedure PopupDeactivate(Sender: TObject);
  public
    constructor CreateFor(AItems: TStrings; AInitialIndex: Integer;
      const AScreenPos: TPoint; APreferredWidth: Integer;
      ADensity: TFRMDDensity; AFontSize: Integer;
      ACallback: TFRMDComboPopupCallback);
  end;

  { TFRMaterialCombo }

  TFRMaterialCombo = class(TFRMaterial3Control, IFRMaterialComponent)
  private
    FItems: TStringList;
    FItemIndex: Integer;
    FVariant: TFRMaterialVariant;
    FBorderRadius: Integer;
    FCaption: TCaption;
    FPlaceholder: TCaption;
    FFocused: Boolean;
    FLabelProgress: Single;
    FPopupOpen: Boolean;
    FOnChange: TNotifyEvent;
    function GetItems: TStrings;
    procedure ItemsChanged(Sender: TObject);
    procedure SetItemIndex(AValue: Integer);
    procedure SetItems(AValue: TStrings);
    procedure SetVariant(AValue: TFRMaterialVariant);
    procedure SetBorderRadius(AValue: Integer);
    procedure SetCaption(const AValue: TCaption);
    function GetSelectedText: string;
    procedure HandlePopupSelect(ANewIndex: Integer);
  protected
    function PaintCached(ABmp: TBGRABitmap): Boolean; override;
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure SetDensity(AValue: TFRMDDensity); override;
    class function GetControlClassDefaultSize: TSize; override;
    { Desenha chrome (borda, label, texto, seta) via Self.Canvas apos
      o blit do bitmap BGRA — usa GDI real com ClearType para texto
      crisp e linhas hardedge 1px, identico ao FRMaterialEdit via
      FieldPainter. }
    procedure DrawChrome;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ApplyTheme(const AThemeManager: TObject); override;
    procedure DropDown;
    procedure CloseUp;
    property SelectedText: string read GetSelectedText;
  published
    property Items: TStrings read GetItems write SetItems;
    property ItemIndex: Integer read FItemIndex write SetItemIndex default -1;
    property Variant: TFRMaterialVariant read FVariant write SetVariant
      default mvOutlined;
    property BorderRadius: Integer read FBorderRadius write SetBorderRadius
      default 4;
    property Caption: TCaption read FCaption write SetCaption;
    property Placeholder: TCaption read FPlaceholder write FPlaceholder;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property Align;
    property Anchors;
    property BorderSpacing;
    property Constraints;
    property Enabled;
    property Font;
    property ParentFont;
    property TabOrder;
    property TabStop;
    property Visible;
  end;

procedure Register;

implementation

uses
  Math;

const
  COMBO_DEFAULT_H      = 56;
  COMBO_PADDING_H      = MD3_FIELD_PADDING_H;
  COMBO_ARROW_SIZE     = 10;
  POPUP_ITEM_H         = 44;
  POPUP_PADDING        = 8;
  POPUP_RADIUS         = 12;
  POPUP_PILL_INSET     = 4;
  POPUP_PILL_RADIUS    = 18;
  POPUP_MAX_VISIBLE    = 8;
  { Search field no topo do popup }
  POPUP_SEARCH_H       = 48;
  POPUP_SEARCH_PAD     = 8;
  POPUP_DIVIDER_H      = 1;
  POPUP_WHEEL_LINES    = 3;
  POPUP_SCROLLBAR_W    = 4;

procedure Register;
begin
  { Icon reutiliza o do Edit ate gerar um dedicado. }
  {$IFDEF FPC}
    {$I icons\frmaterialedit_icon.lrs}
  {$ENDIF}
  RegisterComponents('Material Design 3', [TFRMaterialCombo]);
end;

{ ── TFRMDComboPopup ── }

constructor TFRMDComboPopup.CreateFor(AItems: TStrings; AInitialIndex: Integer;
  const AScreenPos: TPoint; APreferredWidth: Integer;
  ADensity: TFRMDDensity; AFontSize: Integer;
  ACallback: TFRMDComboPopupCallback);
var
  searchH, densityDelta: Integer;
begin
  inherited CreateNew(nil);
  FItems      := AItems;
  FItemIndex  := AInitialIndex;
  FOnSelect   := ACallback;
  FClosing    := False;
  densityDelta := MD3DensityDelta(ADensity);
  FItemHeight := POPUP_ITEM_H + densityDelta;
  if FItemHeight < 24 then FItemHeight := 24;
  FPadding    := POPUP_PADDING;
  FRadius     := POPUP_RADIUS;
  FFilterText := '';
  FTopIndex   := 0;

  { Fonte do popup segue a do controle pai — garante que texto do item
    e do search field escalem junto com a densidade do tema. }
  if AFontSize > 0 then
    Self.Font.Size := AFontSize;
  { Calcula FontHeight para BGRA a partir do Font.Size real.
    Font.Height = -(Size * DPI / 72). Screen.PixelsPerInch costuma ser 96. }
  FFontHeight := -MulDiv(Self.Font.Size, Screen.PixelsPerInch, 72);

  BorderStyle  := bsNone;
  FormStyle    := fsStayOnTop;
  KeyPreview   := True;
  OnDeactivate := @PopupDeactivate;

  { Caret blink — 500ms, sempre visivel quando popup abre (independente
    de ter ou nao texto digitado), serve como affordance visual de que
    o search field aceita input sem precisar clicar nele. }
  FCaretVisible := True;
  FCaretTimer := TTimer.Create(Self);
  FCaretTimer.Interval := 500;
  FCaretTimer.OnTimer := @DoCaretTick;
  FCaretTimer.Enabled := True;

  { Layout fixo: search field no topo + divisor + lista com 8 slots.
    Filtro/scroll mexe no que eh desenhado dentro, nao no tamanho.
    O search field tambem escala com densidade. }
  searchH := POPUP_SEARCH_H + densityDelta;
  if searchH < 28 then searchH := 28;
  FListAreaTop    := FPadding + searchH + POPUP_DIVIDER_H;
  FVisibleCount   := POPUP_MAX_VISIBLE;
  FListAreaHeight := FVisibleCount * FItemHeight;

  Width  := Max(APreferredWidth, 220);
  Height := FListAreaTop + FListAreaHeight + FPadding;

  { Clamp dentro do screen }
  if AScreenPos.X + Width > Screen.Width then
    Left := Screen.Width - Width - 8
  else
    Left := AScreenPos.X;
  if AScreenPos.Y + Height > Screen.Height then
    Top := AScreenPos.Y - Height - 4
  else
    Top := AScreenPos.Y;

  Color := ColorToRGB(MD3Colors.Surface);

  { Popula o filtro inicial (todos os items) e posiciona o cursor no
    item atualmente selecionado, se houver. }
  RebuildFilter;
  if (AInitialIndex >= 0) and (AInitialIndex < FFilteredCount) then
  begin
    FCursorIndex := AInitialIndex;
    EnsureCursorVisible;
  end;
end;

procedure TFRMDComboPopup.DoCaretTick(Sender: TObject);
begin
  FCaretVisible := not FCaretVisible;
  Invalidate;
end;

procedure TFRMDComboPopup.RebuildFilter;
var
  i: Integer;
  lcFilter, lcItem: string;
begin
  SetLength(FFilteredIndices, FItems.Count);
  FFilteredCount := 0;
  if FFilterText = '' then
  begin
    for i := 0 to FItems.Count - 1 do
    begin
      FFilteredIndices[FFilteredCount] := i;
      Inc(FFilteredCount);
    end;
  end
  else
  begin
    lcFilter := LowerCase(FFilterText);
    for i := 0 to FItems.Count - 1 do
    begin
      lcItem := LowerCase(FItems[i]);
      if Pos(lcFilter, lcItem) > 0 then
      begin
        FFilteredIndices[FFilteredCount] := i;
        Inc(FFilteredCount);
      end;
    end;
  end;

  FTopIndex := 0;
  if FFilteredCount > 0 then
    FCursorIndex := 0
  else
    FCursorIndex := -1;

  { Reset do caret para visivel — garante que o usuario ve feedback
    instantaneo ao digitar, sem esperar o proximo tick do blink. }
  FCaretVisible := True;
end;

procedure TFRMDComboPopup.EnsureCursorVisible;
begin
  if FCursorIndex < 0 then Exit;
  if FCursorIndex < FTopIndex then
    FTopIndex := FCursorIndex
  else if FCursorIndex >= FTopIndex + FVisibleCount then
    FTopIndex := FCursorIndex - FVisibleCount + 1;
  if FTopIndex < 0 then FTopIndex := 0;
end;

procedure TFRMDComboPopup.PickCurrent;
begin
  if (FCursorIndex < 0) or (FCursorIndex >= FFilteredCount) then Exit;
  FItemIndex := FFilteredIndices[FCursorIndex];
  if Assigned(FOnSelect) then
    FOnSelect(FItemIndex);
  if not FClosing then
  begin
    FClosing := True;
    if Assigned(FCaretTimer) then FCaretTimer.Enabled := False;
    Close;
    Release;
  end;
end;

function TFRMDComboPopup.PrintableChar(Key: Word; Shift: TShiftState): Char;
begin
  Result := #0;
  if (Key >= Ord('0')) and (Key <= Ord('9')) then
    Result := Chr(Key)
  else if (Key >= Ord('A')) and (Key <= Ord('Z')) then
  begin
    if ssShift in Shift then
      Result := Chr(Key)
    else
      Result := Chr(Key + 32);
  end
  else if Key = VK_SPACE then
    Result := ' ';
end;

procedure TFRMDComboPopup.EraseBackground(DC: HDC);
var
  ARect: TRect;
begin
  if DC = 0 then Exit;
  ARect := Rect(0, 0, Width, Height);
  Brush.Color := ColorToRGB(MD3Colors.Surface);
  LCLIntf.FillRect(DC, ARect, HBRUSH(Brush.Reference.Handle));
end;

procedure TFRMDComboPopup.Paint;
begin
  PaintPopup;
end;

procedure TFRMDComboPopup.PaintPopup;
var
  bmp: TBGRABitmap;
  slot, origIdx, yTop, textY, textLeft: Integer;
  pillRect: TRect;
  searchRect: TRect;
  surfaceColor, containerColor, outlineColor, onSurfaceColor,
    onSurfaceVariantColor, primaryColor: TColor;
  bgColor, fgColor: TColor;
  iconBmp: TBGRABitmap;
  iconHex, displayText: string;
  searchTop, searchBottom, dividerY: Integer;
  textW, caretX, emptyY: Integer;
  thumbHeight, thumbTop, trackX: Integer;
  totalScrollable: Integer;
begin
  if (Width <= 0) or (Height <= 0) then Exit;
  bmp := TBGRABitmap.Create(Width, Height, BGRAPixelTransparent);
  try
    surfaceColor          := ColorToRGB(MD3Colors.Surface);
    containerColor        := ColorToRGB(MD3Colors.SurfaceContainerHighest);
    outlineColor          := ColorToRGB(MD3Colors.OutlineVariant);
    onSurfaceColor        := ColorToRGB(MD3Colors.OnSurface);
    onSurfaceVariantColor := ColorToRGB(MD3Colors.OnSurfaceVariant);
    primaryColor          := ColorToRGB(MD3Colors.Primary);

    { 1) Sombra + card arredondado + borda }
    MD3DrawShadow(bmp, 0, 0, Width, Height, FRadius, elLevel2);
    MD3FillRoundRect(bmp, 0, 0, Width, Height, FRadius, surfaceColor);
    MD3RoundRect(bmp, 0.5, 0.5, Width - 0.5, Height - 0.5, FRadius,
      outlineColor, 1.0);

    { 2) Search field — retangulo arredondado SurfaceContainerHighest com
       icone de lupa a esquerda, texto do filtro, caret. A altura do
       field segue a densidade: FListAreaTop = FPadding + searchH +
       POPUP_DIVIDER_H, entao searchH = FListAreaTop - FPadding - 1. }
    searchTop    := FPadding;
    searchBottom := FListAreaTop - POPUP_DIVIDER_H - (POPUP_SEARCH_PAD div 2);
    searchRect := Rect(FPadding, searchTop,
                       Width - FPadding, searchBottom);
    MD3FillRoundRect(bmp,
      searchRect.Left, searchRect.Top,
      searchRect.Right, searchRect.Bottom,
      (searchRect.Bottom - searchRect.Top) div 2,
      containerColor);

    { Icone lupa }
    iconHex := FRColorToSVGHex(onSurfaceVariantColor);
    iconBmp := FRGetCachedIcon(imSearch, iconHex, 2.0, 18, 18);
    if Assigned(iconBmp) then
      iconBmp.Draw(bmp.Canvas,
        searchRect.Left + 10,
        searchRect.Top + ((searchRect.Bottom - searchRect.Top - 18) div 2),
        False);

    { Texto do filtro (ou placeholder cinza quando vazio) + caret
      piscando sempre visivel como affordance de input.
      Usa bmp.TextOut com fqFineClearTypeRGB + FontHeight hardcoded
      para consistencia com o combo principal (evita discrepancia
      de PPI entre TCustomControl e TForm). }
    bmp.FontName    := Self.Font.Name;
    bmp.FontStyle   := Self.Font.Style;
    bmp.FontHeight  := FFontHeight;
    bmp.FontQuality := fqFineClearTypeRGB;
    textY := searchRect.Top +
      ((searchRect.Bottom - searchRect.Top - bmp.TextSize('Ay').cy) div 2);
    textLeft := searchRect.Left + 36;
    if FFilterText <> '' then
    begin
      bmp.TextOut(textLeft, textY, FFilterText, ColorToBGRA(onSurfaceColor));
      textW := bmp.TextSize(FFilterText).cx;
      caretX := textLeft + textW + 2;
    end
    else
    begin
      bmp.TextOut(textLeft + 10, textY, 'Pesquisar...',
        ColorToBGRA(onSurfaceVariantColor));
      caretX := textLeft;
    end;
    { Caret piscando sempre desenhado quando FCaretVisible. }
    if FCaretVisible then
      bmp.DrawLineAntialias(caretX, textY,
        caretX, textY + bmp.TextSize('Ay').cy,
        ColorToBGRA(primaryColor), 1.8);

    { 3) Divisor fino abaixo do search }
    dividerY := searchRect.Bottom + POPUP_SEARCH_PAD div 2;
    bmp.DrawLine(FPadding, dividerY, Width - FPadding, dividerY,
      ColorToBGRA(outlineColor), False);

    { 4) Empty state quando nenhum item bate com o filtro }
    if FFilteredCount = 0 then
    begin
      emptyY := FListAreaTop +
        (FListAreaHeight - bmp.TextSize('Ay').cy) div 2;
      bmp.TextOut(FPadding + 16, emptyY, 'Nenhum resultado',
        ColorToBGRA(onSurfaceVariantColor));
      bmp.Draw(Canvas, 0, 0, False);
      Exit;
    end;

    { 5) Itens visiveis — so desenha slot..slot+VisibleCount-1, mapeando
       para FFilteredIndices[FTopIndex + slot]. }
    for slot := 0 to FVisibleCount - 1 do
    begin
      if FTopIndex + slot >= FFilteredCount then Break;
      origIdx := FFilteredIndices[FTopIndex + slot];
      yTop := FListAreaTop + slot * FItemHeight;

      { Prioridade de highlight:
          1) cursor teclado (FCursorIndex)           -> hover state-layer
          2) item selecionado                        -> pill secondaria
          3) nenhum                                  -> texto plain }
      if (FTopIndex + slot) = FCursorIndex then
      begin
        if origIdx = FItemIndex then
        begin
          { Cursor + selecionado: ainda o pill secundario }
          bgColor := ColorToRGB(MD3Colors.SecondaryContainer);
          fgColor := ColorToRGB(MD3Colors.OnSecondaryContainer);
        end
        else
        begin
          bgColor := MD3Blend(surfaceColor, onSurfaceColor,
            MD3StateOpacity(isHovered));
          fgColor := onSurfaceColor;
        end;
        pillRect := Rect(FPadding + POPUP_PILL_INSET,
                         yTop + 2,
                         Width - FPadding - POPUP_PILL_INSET - POPUP_SCROLLBAR_W - 2,
                         yTop + FItemHeight - 2);
        MD3FillRoundRect(bmp,
          pillRect.Left, pillRect.Top,
          pillRect.Right, pillRect.Bottom,
          POPUP_PILL_RADIUS, bgColor);
      end
      else if origIdx = FItemIndex then
      begin
        bgColor := ColorToRGB(MD3Colors.SecondaryContainer);
        fgColor := ColorToRGB(MD3Colors.OnSecondaryContainer);
        pillRect := Rect(FPadding + POPUP_PILL_INSET,
                         yTop + 2,
                         Width - FPadding - POPUP_PILL_INSET - POPUP_SCROLLBAR_W - 2,
                         yTop + FItemHeight - 2);
        MD3FillRoundRect(bmp,
          pillRect.Left, pillRect.Top,
          pillRect.Right, pillRect.Bottom,
          POPUP_PILL_RADIUS, bgColor);
      end
      else
        fgColor := onSurfaceColor;

      textLeft := FPadding + POPUP_PILL_INSET + 16;

      { Checkmark so no item selecionado (match por indice original) }
      if origIdx = FItemIndex then
      begin
        iconHex := FRColorToSVGHex(fgColor);
        iconBmp := FRGetCachedIcon(imCheck, iconHex, 2.0, 18, 18);
        if Assigned(iconBmp) then
        begin
          iconBmp.Draw(bmp.Canvas,
            FPadding + POPUP_PILL_INSET + 12,
            yTop + (FItemHeight - 18) div 2, False);
          textLeft := FPadding + POPUP_PILL_INSET + 12 + 18 + 8;
        end;
      end;

      displayText := FItems[origIdx];
      textY := yTop + ((FItemHeight - bmp.TextSize('Ay').cy) div 2);
      bmp.TextOut(textLeft, textY, displayText, ColorToBGRA(fgColor));
    end;

    { 6) Scrollbar MD3 — barra fina do lado direito quando tem mais itens
       do que cabem na area visivel. }
    if FFilteredCount > FVisibleCount then
    begin
      totalScrollable := FFilteredCount - FVisibleCount;
      if totalScrollable < 1 then totalScrollable := 1;
      thumbHeight := Max(24,
        (FVisibleCount * FListAreaHeight) div FFilteredCount);
      thumbTop := FListAreaTop +
        (FTopIndex * (FListAreaHeight - thumbHeight)) div totalScrollable;
      trackX := Width - FPadding - POPUP_SCROLLBAR_W;
      MD3FillRoundRect(bmp,
        trackX, thumbTop,
        trackX + POPUP_SCROLLBAR_W, thumbTop + thumbHeight,
        POPUP_SCROLLBAR_W div 2,
        outlineColor);
    end;

    bmp.Draw(Canvas, 0, 0, False);
  finally
    bmp.Free;
  end;
end;

function TFRMDComboPopup.ItemAtY(AY: Integer): Integer;
var
  slot: Integer;
begin
  Result := -1;
  if AY < FListAreaTop then Exit;
  if AY >= FListAreaTop + FListAreaHeight then Exit;
  slot := (AY - FListAreaTop) div FItemHeight;
  if (slot < 0) or (slot >= FVisibleCount) then Exit;
  if FTopIndex + slot >= FFilteredCount then Exit;
  Result := FTopIndex + slot;
end;

procedure TFRMDComboPopup.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  NewCursor: Integer;
begin
  inherited MouseMove(Shift, X, Y);
  NewCursor := ItemAtY(Y);
  if (NewCursor >= 0) and (NewCursor <> FCursorIndex) then
  begin
    FCursorIndex := NewCursor;
    Invalidate;
  end;
end;

procedure TFRMDComboPopup.MouseLeave;
begin
  inherited MouseLeave;
  { Mouse leave nao mexe em FCursorIndex — o teclado continua navegando. }
end;

procedure TFRMDComboPopup.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  Idx: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);
  if Button <> mbLeft then Exit;
  Idx := ItemAtY(Y);
  if Idx < 0 then Exit;
  FCursorIndex := Idx;
  PickCurrent;
end;

function TFRMDComboPopup.DoMouseWheel(Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint): Boolean;
var
  Lines: Integer;
begin
  Result := True;
  if FFilteredCount <= FVisibleCount then Exit;
  Lines := POPUP_WHEEL_LINES;
  if WheelDelta > 0 then
    Dec(FTopIndex, Lines)
  else
    Inc(FTopIndex, Lines);
  if FTopIndex < 0 then FTopIndex := 0;
  if FTopIndex > FFilteredCount - FVisibleCount then
    FTopIndex := FFilteredCount - FVisibleCount;
  Invalidate;
end;

procedure TFRMDComboPopup.KeyDown(var Key: Word; Shift: TShiftState);
var
  Ch: Char;
begin
  inherited KeyDown(Key, Shift);
  case Key of
    VK_UP:
    begin
      if FCursorIndex > 0 then
      begin
        Dec(FCursorIndex);
        EnsureCursorVisible;
        Invalidate;
      end;
      Key := 0;
    end;
    VK_DOWN:
    begin
      if FCursorIndex < FFilteredCount - 1 then
      begin
        Inc(FCursorIndex);
        EnsureCursorVisible;
        Invalidate;
      end;
      Key := 0;
    end;
    VK_PRIOR: { Page Up }
    begin
      Dec(FCursorIndex, FVisibleCount);
      if FCursorIndex < 0 then FCursorIndex := 0;
      EnsureCursorVisible;
      Invalidate;
      Key := 0;
    end;
    VK_NEXT: { Page Down }
    begin
      Inc(FCursorIndex, FVisibleCount);
      if FCursorIndex >= FFilteredCount then
        FCursorIndex := FFilteredCount - 1;
      EnsureCursorVisible;
      Invalidate;
      Key := 0;
    end;
    VK_HOME:
    begin
      FCursorIndex := 0;
      EnsureCursorVisible;
      Invalidate;
      Key := 0;
    end;
    VK_END:
    begin
      FCursorIndex := FFilteredCount - 1;
      EnsureCursorVisible;
      Invalidate;
      Key := 0;
    end;
    VK_RETURN:
    begin
      PickCurrent;
      Key := 0;
    end;
    VK_ESCAPE:
    begin
      if not FClosing then
      begin
        FClosing := True;
        if Assigned(FCaretTimer) then FCaretTimer.Enabled := False;
        Close;
        Release;
      end;
      Key := 0;
    end;
    VK_BACK:
    begin
      if FFilterText <> '' then
      begin
        SetLength(FFilterText, Length(FFilterText) - 1);
        RebuildFilter;
        Invalidate;
      end;
      Key := 0;
    end;
  else
    { Letras/digitos/espaco vao para o filtro via KeyDown. UTF8KeyPress
      tambem cobre acentos — aqui tratamos so ASCII como fallback. }
    if (not (ssCtrl in Shift)) and (not (ssAlt in Shift)) then
    begin
      Ch := PrintableChar(Key, Shift);
      if Ch <> #0 then
      begin
        FFilterText := FFilterText + Ch;
        RebuildFilter;
        Invalidate;
        Key := 0;
      end;
    end;
  end;
end;

procedure TFRMDComboPopup.UTF8KeyPress(var UTF8Key: TUTF8Char);
var
  First: Char;
begin
  inherited UTF8KeyPress(UTF8Key);
  if UTF8Key = '' then Exit;
  First := UTF8Key[1];
  { ASCII imprimivel: ja foi processado pelo KeyDown (alpha/num/space).
    Aqui pegamos caracteres UTF-8 multibyte (acentos). }
  if (Length(UTF8Key) > 1) or (First >= #32) then
  begin
    if (Length(UTF8Key) > 1) or
       ((First >= #32) and not (First in ['a'..'z','A'..'Z','0'..'9',' '])) then
    begin
      FFilterText := FFilterText + UTF8Key;
      RebuildFilter;
      Invalidate;
      UTF8Key := '';
    end;
  end;
end;

procedure TFRMDComboPopup.PopupDeactivate(Sender: TObject);
begin
  if not FClosing then
  begin
    FClosing := True;
    if Assigned(FCaretTimer) then FCaretTimer.Enabled := False;
    Close;
    Release;
  end;
end;

{ ── TFRMaterialCombo ── }

constructor TFRMaterialCombo.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FItems := TStringList.Create;
  FItems.OnChange := @ItemsChanged;
  FItemIndex     := -1;
  FVariant       := mvOutlined;  { fallback se nao houver theme manager }
  FBorderRadius  := 0;  { default 0 = cantos retos, igual TFRMaterialEditBase }
  FCaption       := 'Label';
  FPlaceholder   := '';
  FFocused       := False;
  FLabelProgress := 0;
  FPopupOpen     := False;
  TabStop        := True;
  Width          := 240;
  Height         := COMBO_DEFAULT_H;

  { O TFRMaterialThemeManager.RegisterComponent NAO chama ApplyTheme
    automaticamente no registro — o constructor do descendente ainda
    nao rodou quando o base registra, entao chamar virtualmente ali
    crasha com AV em campos nil. Em vez disso, cada descendente chama
    ApplyTheme aqui, depois de todos os fields estarem inicializados.
    Mesmo padrao usado em TFRMaterialEditBase.Create. }
  if Assigned(FRMaterialDefaultThemeManager) then
    Self.ApplyTheme(FRMaterialDefaultThemeManager);
end;

destructor TFRMaterialCombo.Destroy;
begin
  FreeAndNil(FItems);
  inherited Destroy;
end;

class function TFRMaterialCombo.GetControlClassDefaultSize: TSize;
begin
  Result.cx := 240;
  Result.cy := COMBO_DEFAULT_H;
end;

procedure TFRMaterialCombo.SetDensity(AValue: TFRMDDensity);
var
  NewH: Integer;
begin
  inherited SetDensity(AValue);
  { inherited ja setou FDensity e disparou DoOnResize+Invalidate.
    Aqui ajustamos a altura base + o tamanho da fonte para acompanhar
    o delta de densidade MD3. }
  NewH := COMBO_DEFAULT_H + MD3DensityDelta(AValue);
  if NewH < 32 then NewH := 32;
  if Height <> NewH then
    Height := NewH;
  Self.Font.Size := MD3FontSizeForField(NewH, AValue);
  InvalidatePaintCache;
  FRMDSafeInvalidate(Self);
end;

procedure TFRMaterialCombo.ItemsChanged(Sender: TObject);
begin
  if FItemIndex >= FItems.Count then
    FItemIndex := -1;
  InvalidatePaintCache;
  FRMDSafeInvalidate(Self);
end;

function TFRMaterialCombo.GetItems: TStrings;
begin
  Result := FItems;
end;

procedure TFRMaterialCombo.SetItems(AValue: TStrings);
begin
  FItems.Assign(AValue);
end;

procedure TFRMaterialCombo.SetItemIndex(AValue: Integer);
begin
  if (AValue < -1) or (AValue >= FItems.Count) then Exit;
  if FItemIndex = AValue then Exit;
  FItemIndex := AValue;
  if (FItemIndex >= 0) or FFocused then
    FLabelProgress := 1.0
  else
    FLabelProgress := 0.0;
  InvalidatePaintCache;
  FRMDSafeInvalidate(Self);
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TFRMaterialCombo.SetVariant(AValue: TFRMaterialVariant);
begin
  if FVariant = AValue then Exit;
  FVariant := AValue;
  InvalidatePaintCache;
  FRMDSafeInvalidate(Self);
end;

procedure TFRMaterialCombo.SetBorderRadius(AValue: Integer);
begin
  if AValue < 0 then AValue := 0;
  if FBorderRadius = AValue then Exit;
  FBorderRadius := AValue;
  InvalidatePaintCache;
  FRMDSafeInvalidate(Self);
end;

procedure TFRMaterialCombo.SetCaption(const AValue: TCaption);
begin
  if FCaption = AValue then Exit;
  FCaption := AValue;
  InvalidatePaintCache;
  FRMDSafeInvalidate(Self);
end;

function TFRMaterialCombo.GetSelectedText: string;
begin
  if (FItemIndex >= 0) and (FItemIndex < FItems.Count) then
    Result := FItems[FItemIndex]
  else
    Result := '';
end;

procedure TFRMaterialCombo.ApplyTheme(const AThemeManager: TObject);
begin
  inherited ApplyTheme(AThemeManager);
  if toVariant in SyncWithTheme then
    FVariant := FRMDGetThemeVariant(AThemeManager);
  { toDensity: sincroniza densidade via SetDensity (que ajusta Height e
    font size). O inherited ja checa toColor/variant/density para o Color,
    mas nao propaga pro nosso SetDensity override. }
  if toDensity in SyncWithTheme then
    SetDensity(FRMDGetThemeDensity(AThemeManager));
  InvalidatePaintCache;
  FRMDSafeInvalidate(Self);
end;

function TFRMaterialCombo.PaintCached(ABmp: TBGRABitmap): Boolean;
var
  bgColor: TColor;
begin
  Result := True;

  { Coordenadas alinhadas com o FieldPainter do FRMaterialEdit:
      Fill interior: (0, 0, Width, Height) para filled
                     (0, 8, Width, Height) para outlined
      Border em DrawChrome: (0, 8, Width, Height - 1)
    Antes usava Height - 4 aqui, o que deixava uma tira vertical
    de 4px na base sem fill e a borda 3px mais alta do que nos
    outros edits. }
  case FVariant of
    mvFilled:
    begin
      bgColor := ColorToRGB(MD3Colors.SurfaceContainerHighest);
      MD3FillTopRoundRect(ABmp, 0, 0, Width, Height,
        FBorderRadius, bgColor, 255);
    end;
    mvOutlined:
    begin
      { Y deve casar com o fieldTop calculado em DrawChrome:
        fieldTop = 4 + labelH div 2.  Aproximamos com BGRA font metrics. }
      bgColor := ColorToRGB(MD3Colors.Surface);
      ABmp.FontName := Self.Font.Name;
      ABmp.FontStyle := [fsBold];
      ABmp.FontFullHeight := Abs(MulDiv(8, Screen.PixelsPerInch, 72));
      MD3FillRoundRect(ABmp, 0, 4 + ABmp.TextSize('A').cy div 2,
        Width, Height, FBorderRadius, bgColor);
    end;
    { mvStandard: sem fill — so sublinhado, desenhado em DrawChrome }
  end;
end;

procedure TFRMaterialCombo.Paint;
begin
  inherited Paint;  { blita o bitmap BGRA com o background }
  if not FRMDCanPaint(Self) then Exit;
  DrawChrome;       { borda + label + texto + seta via Self.Canvas (GDI) }
end;

procedure TFRMaterialCombo.DrawChrome;
var
  borderColor, textColor, labelColor, arrowColor, notchBgColor: TColor;
  labelY, textY, arrowX, arrowY, fieldTop, labelH, penW: Integer;
  notchLeft, notchRight: Integer;
  txt: string;
  labelScaled: Boolean;
  arrowPoly: array[0..2] of TPoint;
begin
  { Resolve cores conforme variant/focus. Borda e underline usam
    OnSurfaceVariant unfocused (mesmo token que FRMaterialEdit
    via FieldPainter.DisabledColor) para casar consistencia visual. }
  if FFocused then
    borderColor := ColorToRGB(MD3Colors.Primary)
  else
    borderColor := ColorToRGB(MD3Colors.OnSurfaceVariant);

  textColor  := ColorToRGB(MD3Colors.OnSurface);
  labelColor := borderColor;
  if FFocused then
    arrowColor := ColorToRGB(MD3Colors.Primary)
  else
    arrowColor := ColorToRGB(MD3Colors.OnSurfaceVariant);

  labelScaled := (FLabelProgress > 0.5) or (FItemIndex >= 0) or FFocused;

  { Calcula FieldTop idêntico ao FieldPainter.DrawField para outlined:
    FieldTop = LabelTop + LabelH div 2.  Garante que a borda do combo
    comece na mesma posição Y que os edits. }
  Canvas.Font.Assign(Self.Font);
  Canvas.Font.Size  := 8;
  Canvas.Font.Style := [fsBold];
  labelH := Canvas.TextHeight(FCaption);
  fieldTop := 4 + labelH div 2; { 4 = FLabel.Top dos edits }

  { 1) Borda ou underline por variant }
  Canvas.Brush.Style := bsClear;
  Canvas.Pen.Style   := psSolid;
  Canvas.Pen.Color   := borderColor;
  if FFocused then
    penW := 2
  else
    penW := 1;
  Canvas.Pen.Width := penW;

  case FVariant of
    mvOutlined:
      Canvas.RoundRect(0, fieldTop, Width, Height - 1,
        FBorderRadius * 2, FBorderRadius * 2);
    mvStandard, mvFilled:
    begin
      if FVariant = mvFilled then
      begin
        if FFocused then
          Canvas.Pen.Color := ColorToRGB(MD3Colors.Primary)
        else
          Canvas.Pen.Color := ColorToRGB(MD3Colors.OnSurfaceVariant);
      end;
      Canvas.MoveTo(0, Height - 2);
      Canvas.LineTo(Width, Height - 2);
    end;
  end;
  Canvas.Pen.Width := 1;

  { 2) Notch (cobre a borda superior atrás do label no outlined) }
  if (FVariant = mvOutlined) and labelScaled then
  begin
    notchLeft := COMBO_PADDING_H - 4;
    notchRight := COMBO_PADDING_H + Canvas.TextWidth(FCaption) + 4;
    notchBgColor := ColorToRGB(MD3Colors.Surface);
    Canvas.Brush.Color := notchBgColor;
    Canvas.Brush.Style := bsSolid;
    Canvas.Pen.Style   := psClear;
    Canvas.FillRect(notchLeft, fieldTop - 1, notchRight, fieldTop + penW + 1);
    Canvas.Brush.Style := bsClear;
    Canvas.Pen.Style   := psSolid;
  end;

  { 3) Label — bold para casar com TBoundLabel dos outros edits }
  Canvas.Font.Assign(Self.Font);
  Canvas.Font.Style := [fsBold];
  Canvas.Brush.Style := bsClear;
  if labelScaled then
  begin
    Canvas.Font.Size  := 8;
    Canvas.Font.Color := labelColor;
    labelY := 4; { Alinhado com FLabel.Top dos edits (FieldPainter) }
    Canvas.TextOut(COMBO_PADDING_H, labelY, FCaption);
  end
  else
  begin
    Canvas.Font.Color := labelColor;
    labelY := (Height - Canvas.TextHeight('Ay')) div 2;
    Canvas.TextOut(COMBO_PADDING_H, labelY, FCaption);
  end;

  { 4) Texto do item atual — regular weight, fonte full }
  if FItemIndex >= 0 then
    txt := GetSelectedText
  else
    txt := FPlaceholder;
  if (txt <> '') and labelScaled then
  begin
    Canvas.Font.Assign(Self.Font);
    Canvas.Font.Style := [];
    Canvas.Font.Color := textColor;
    textY := Height div 2 - 2;
    Canvas.TextOut(COMBO_PADDING_H, textY, txt);
  end;

  { 5) Triangulo de dropdown (preenchido, GDI Polygon nao-AA) }
  arrowX := Width - COMBO_PADDING_H - COMBO_ARROW_SIZE;
  arrowY := Height div 2 - 2;
  if FPopupOpen then
  begin
    arrowPoly[0] := Point(arrowX, arrowY + COMBO_ARROW_SIZE div 2);
    arrowPoly[1] := Point(arrowX + COMBO_ARROW_SIZE,
      arrowY + COMBO_ARROW_SIZE div 2);
    arrowPoly[2] := Point(arrowX + COMBO_ARROW_SIZE div 2,
      arrowY - COMBO_ARROW_SIZE div 2);
  end
  else
  begin
    arrowPoly[0] := Point(arrowX, arrowY - COMBO_ARROW_SIZE div 2);
    arrowPoly[1] := Point(arrowX + COMBO_ARROW_SIZE,
      arrowY - COMBO_ARROW_SIZE div 2);
    arrowPoly[2] := Point(arrowX + COMBO_ARROW_SIZE div 2,
      arrowY + COMBO_ARROW_SIZE div 2);
  end;
  Canvas.Brush.Color := arrowColor;
  Canvas.Brush.Style := bsSolid;
  Canvas.Pen.Color   := arrowColor;
  Canvas.Pen.Style   := psSolid;
  Canvas.Polygon(arrowPoly);
end;

procedure TFRMaterialCombo.MouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and Enabled then
  begin
    if CanFocus then SetFocus;
    if FPopupOpen then
      CloseUp
    else
      DropDown;
  end;
end;

procedure TFRMaterialCombo.DoEnter;
begin
  inherited DoEnter;
  FFocused := True;
  FLabelProgress := 1.0;
  InvalidatePaintCache;
  FRMDSafeInvalidate(Self);
end;

procedure TFRMaterialCombo.DoExit;
begin
  inherited DoExit;
  FFocused := False;
  if FItemIndex < 0 then
    FLabelProgress := 0;
  InvalidatePaintCache;
  FRMDSafeInvalidate(Self);
end;

procedure TFRMaterialCombo.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  case Key of
    VK_DOWN, VK_SPACE, VK_RETURN:
    begin
      if not FPopupOpen then DropDown;
      Key := 0;
    end;
    VK_UP:
    begin
      if (not FPopupOpen) and (FItemIndex > 0) then
      begin
        ItemIndex := FItemIndex - 1;
        Key := 0;
      end;
    end;
  end;
end;

procedure TFRMaterialCombo.DropDown;
var
  ScreenPt: TPoint;
  Popup: TFRMDComboPopup;
begin
  if FPopupOpen then Exit;
  if FItems.Count = 0 then Exit;
  FPopupOpen := True;
  InvalidatePaintCache;
  FRMDSafeInvalidate(Self);

  ScreenPt := Self.ClientToScreen(Point(0, Height));
  Popup := TFRMDComboPopup.CreateFor(FItems, FItemIndex, ScreenPt, Width,
    Density, Self.Font.Size, @HandlePopupSelect);
  Popup.Show;
end;

procedure TFRMaterialCombo.CloseUp;
begin
  if not FPopupOpen then Exit;
  FPopupOpen := False;
  InvalidatePaintCache;
  FRMDSafeInvalidate(Self);
end;

procedure TFRMaterialCombo.HandlePopupSelect(ANewIndex: Integer);
begin
  CloseUp;
  if ANewIndex <> FItemIndex then
    ItemIndex := ANewIndex;
end;

end.
