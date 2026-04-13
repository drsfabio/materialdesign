unit FRMaterialDateEdit;

{$mode objfpc}{$H+}

{ TFRMaterialDateEdit — Material Design 3

  Campo de data herdado de TFRMaterialEditBase<TFRInternalEdit>. Reutiliza
  todo o chrome do MaterialEdit (label flutuante, variants, painter,
  density, clear button) e adiciona apenas:

    - FCalendarButton (icone calendario a direita, sempre visivel)
    - FCalendarPopup (TForm stayontop com TCalendar)
    - FDate: TDateTime + FDateFormat: TFRDateFormat
    - Filtro de teclas (so digitos + /)
    - Mascara automatica (dd/mm/yyyy ou mm/yyyy)
    - Parse robusto com validacao via EncodeDate
    - Navegacao por segmentos (UP/DOWN incrementa dia/mes/ano)

  Antes do refactor eram 1251 linhas duplicando chrome. Depois, ~400
  linhas focadas so no comportamento de data.

  Licenca: LGPL v3
}

interface

uses
  Classes, SysUtils, Controls, Graphics, Forms,
  {$IFDEF FPC} LCLType, LResources, {$ENDIF}
  FRMaterialTheme, FRMaterial3Base, FRMaterial3DatePicker, FRMaterialIcons,
  FRMaterialInternalEdits, FRMaterialEdit;

type
  TFRDateFormat = (dfDDMMYYYY, dfMMYYYY);

  { TFRMaterialDateEdit }

  TFRMaterialDateEdit = class(specialize TFRMaterialEditBase<TFRInternalEdit>)
  private
    FCalendarButton: TFRMaterialIconButton;
    FCalendarPopup: TForm;
    FCalendar: TFRMaterialDatePicker;
    FDate: TDateTime;
    FDateFormat: TFRDateFormat;
    FUpdating: Boolean;
    FDateUserOnKeyPress: TKeyPressEvent;
    FDateUserOnKeyDown: TKeyEvent;

    { Mascara / parse }
    procedure InternalDateChange(Sender: TObject);
    procedure InternalKeyPress(Sender: TObject; var Key: Char);
    procedure InternalKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ApplyMask;
    function ParseDate: TDateTime;
    procedure RefreshDisplay;

    { Segment navigation (UP/DOWN ajusta o segmento atual) }
    function IsTextComplete: Boolean;
    function GetCurrentSegment: Integer;
    procedure SelectSegment(ASegment: Integer);
    procedure AdjustSegmentValue(ADelta: Integer);

    { Calendar popup }
    procedure CalendarButtonClick(Sender: TObject);
    procedure CalendarDblClick(Sender: TObject);
    procedure CalendarPopupDeactivate(Sender: TObject);

    { Properties }
    function GetDate: TDateTime;
    procedure SetDate(AValue: TDateTime);
    procedure SetDateFormat(AValue: TFRDateFormat);
  protected
    procedure DoOnResize; override;
    procedure ApplyTheme(const AThemeManager: TObject); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ClearDate;
    { Botao calendario (readonly) — customizacao de hint/cor/etc. }
    property CalendarButton: TFRMaterialIconButton read FCalendarButton;
  published
    { Data selecionada. 0 = sem data. Escrita dispara RefreshDisplay. }
    property Date: TDateTime read GetDate write SetDate;
    { Formato: dd/mm/yyyy (padrao) ou mm/yyyy. }
    property DateFormat: TFRDateFormat read FDateFormat write SetDateFormat
      default dfDDMMYYYY;
    { OnKeyPress e OnKeyDown precisam ser shadowados porque a base delega
      direto ao FEdit, e a gente intercepta FEdit.OnKeyPress/OnKeyDown
      para filtrar digitos e navegar segmentos. }
    property OnKeyPress: TKeyPressEvent read FDateUserOnKeyPress
      write FDateUserOnKeyPress;
    property OnKeyDown: TKeyEvent read FDateUserOnKeyDown
      write FDateUserOnKeyDown;
  end;

procedure Register;

implementation

uses
  DateUtils
  {$IFDEF MSWINDOWS}, LCLIntf{$ENDIF};

{$IFDEF MSWINDOWS}
function CreateRoundRectRgn(X1, Y1, X2, Y2, W, H: Integer): HRGN;
  stdcall; external 'gdi32.dll';
function SetWindowRgn(hWnd: HWND; hRgn: HRGN; bRedraw: LongBool): Integer;
  stdcall; external 'user32.dll';
{$ENDIF}

procedure Register;
begin
  {$IFDEF FPC}
    {$I icons\frmaterialdateedit_icon.lrs}
  {$ENDIF}
  RegisterComponents('Material Design 3', [TFRMaterialDateEdit]);
end;

{ ── Helpers locais ── }

function OnlyDigits(const S: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(S) do
    if S[I] in ['0'..'9'] then
      Result := Result + S[I];
end;

function FormatDateMask(const ADigits: string; AFormat: TFRDateFormat): string;
var
  D: string;
begin
  D := ADigits;
  case AFormat of
    dfDDMMYYYY:
    begin
      if Length(D) > 8 then D := Copy(D, 1, 8);
      Result := D;
      if Length(D) > 2 then Insert('/', Result, 3);
      if Length(D) > 4 then Insert('/', Result, 6);
    end;
    dfMMYYYY:
    begin
      if Length(D) > 6 then D := Copy(D, 1, 6);
      Result := D;
      if Length(D) > 2 then Insert('/', Result, 3);
    end;
  end;
end;

function MaxDigitsForFormat(AFormat: TFRDateFormat): Integer;
begin
  case AFormat of
    dfDDMMYYYY: Result := 8;
    dfMMYYYY:   Result := 6;
  else
    Result := 8;
  end;
end;

{ ── TFRMaterialDateEdit ── }

constructor TFRMaterialDateEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FDateFormat    := dfDDMMYYYY;
  FDate          := 0;
  FUpdating      := False;
  FCalendarPopup := nil;
  FCalendar      := nil;

  { FCalendarButton vive como irmao dos 5 botoes que o base criou. Fica
    sempre visivel, ancora a direita do FEdit (apos qualquer botao que
    o base tenha posicionado), e dispara o popup do TCalendar. }
  FCalendarButton := TFRMaterialIconButton.Create(Self);
  FCalendarButton.IconMode    := imCalendar;
  FCalendarButton.NormalColor := MD3Colors.OnSurfaceVariant;
  FCalendarButton.HoverColor  := MD3Colors.Primary;
  FCalendarButton.Width       := 22;
  FCalendarButton.Height      := 22;
  FCalendarButton.Visible     := True;
  FCalendarButton.Parent      := Self;
  FCalendarButton.OnClick     := @CalendarButtonClick;
  FCalendarButton.SetSubComponent(True);

  { Intercepta teclas e mudancas do FEdit:
      OnKeyPress  → filtra non-digit
      OnKeyDown   → navegacao por segmentos (UP/DOWN/LEFT/RIGHT)
      OnChange    → aplica mascara e re-parseia data
    Os tres delegam ao user handler depois do trabalho interno. }
  FEdit.OnKeyPress := @InternalKeyPress;
  FEdit.OnKeyDown  := @InternalKeyDown;
  FEdit.AddHandlerOnChange(@InternalDateChange);

  { Default caption diferente de "Label" do base. }
  if EditLabel.Caption = 'Label' then
    EditLabel.Caption := 'Data';

  { Estado inicial: texto vazio (FDate = 0). }
  FEdit.Text := '';
end;

destructor TFRMaterialDateEdit.Destroy;
begin
  { Evita callbacks tardios do popup apos o destructor do base liberar
    o FEdit / icon buttons. }
  if Assigned(FCalendarButton) then
    FCalendarButton.OnClick := nil;
  FreeAndNil(FCalendarPopup);
  inherited Destroy;
end;

{ ── Mascara e parse ── }

procedure TFRMaterialDateEdit.InternalDateChange(Sender: TObject);
begin
  if FUpdating then Exit;
  FUpdating := True;
  try
    ApplyMask;
    FDate := ParseDate;
  finally
    FUpdating := False;
  end;
end;

procedure TFRMaterialDateEdit.InternalKeyPress(Sender: TObject; var Key: Char);
begin
  { Aceita digitos, backspace (#8) e delete (#127). Outros caracteres sao
    bloqueados (Key := #0) antes de o LCL inserir no texto. }
  if not (Key in ['0'..'9', #8, #127]) then
    Key := #0;
  if Assigned(FDateUserOnKeyPress) then
    FDateUserOnKeyPress(Sender, Key);
end;

procedure TFRMaterialDateEdit.InternalKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  Seg, MaxSeg: Integer;
begin
  if IsTextComplete then
  begin
    case Key of
      VK_UP:
      begin
        AdjustSegmentValue(1);
        Key := 0;
      end;
      VK_DOWN:
      begin
        AdjustSegmentValue(-1);
        Key := 0;
      end;
      VK_LEFT:
      begin
        Seg := GetCurrentSegment;
        if Seg > 0 then
        begin
          SelectSegment(Seg - 1);
          Key := 0;
        end;
      end;
      VK_RIGHT:
      begin
        Seg := GetCurrentSegment;
        case FDateFormat of
          dfDDMMYYYY: MaxSeg := 2;
          dfMMYYYY:   MaxSeg := 1;
        else
          MaxSeg := 2;
        end;
        if Seg < MaxSeg then
        begin
          SelectSegment(Seg + 1);
          Key := 0;
        end;
      end;
    end;
  end;
  if Assigned(FDateUserOnKeyDown) then
    FDateUserOnKeyDown(Sender, Key, Shift);
end;

procedure TFRMaterialDateEdit.ApplyMask;
var
  Digits, Formatted: string;
begin
  Digits := OnlyDigits(FEdit.Text);
  if Length(Digits) > MaxDigitsForFormat(FDateFormat) then
    Digits := Copy(Digits, 1, MaxDigitsForFormat(FDateFormat));
  Formatted := FormatDateMask(Digits, FDateFormat);
  if FEdit.Text <> Formatted then
  begin
    FEdit.Text := Formatted;
    FEdit.SelStart := Length(Formatted);
  end;
end;

function TFRMaterialDateEdit.ParseDate: TDateTime;
var
  Digits: string;
  D, M, Y: Word;
begin
  Result := 0;
  Digits := OnlyDigits(FEdit.Text);
  case FDateFormat of
    dfDDMMYYYY:
    begin
      if Length(Digits) <> 8 then Exit;
      D := StrToIntDef(Copy(Digits, 1, 2), 0);
      M := StrToIntDef(Copy(Digits, 3, 2), 0);
      Y := StrToIntDef(Copy(Digits, 5, 4), 0);
      if (D < 1) or (D > 31) or (M < 1) or (M > 12) or (Y < 1) then Exit;
      try
        Result := EncodeDate(Y, M, D);
      except
        Result := 0;
      end;
    end;
    dfMMYYYY:
    begin
      if Length(Digits) <> 6 then Exit;
      M := StrToIntDef(Copy(Digits, 1, 2), 0);
      Y := StrToIntDef(Copy(Digits, 3, 4), 0);
      if (M < 1) or (M > 12) or (Y < 1) then Exit;
      try
        Result := EncodeDate(Y, M, 1);
      except
        Result := 0;
      end;
    end;
  end;
end;

procedure TFRMaterialDateEdit.RefreshDisplay;
var
  Y, M, D: Word;
begin
  FUpdating := True;
  try
    if FDate < 1 then
    begin
      FEdit.Text := '';
      Exit;
    end;
    DecodeDate(FDate, Y, M, D);
    case FDateFormat of
      dfDDMMYYYY: FEdit.Text := Format('%.2d/%.2d/%.4d', [D, M, Y]);
      dfMMYYYY:   FEdit.Text := Format('%.2d/%.4d', [M, Y]);
    end;
  finally
    FUpdating := False;
  end;
end;

{ ── Segment navigation ── }

function TFRMaterialDateEdit.IsTextComplete: Boolean;
begin
  case FDateFormat of
    dfDDMMYYYY: Result := Length(FEdit.Text) = 10;
    dfMMYYYY:   Result := Length(FEdit.Text) = 7;
  else
    Result := False;
  end;
end;

function TFRMaterialDateEdit.GetCurrentSegment: Integer;
var
  P: Integer;
begin
  P := FEdit.SelStart;
  case FDateFormat of
    dfDDMMYYYY:
    begin
      if P < 3 then Result := 0
      else if P < 6 then Result := 1
      else Result := 2;
    end;
    dfMMYYYY:
    begin
      if P < 3 then Result := 0
      else Result := 1;
    end;
  else
    Result := 0;
  end;
end;

procedure TFRMaterialDateEdit.SelectSegment(ASegment: Integer);
begin
  case FDateFormat of
    dfDDMMYYYY:
      case ASegment of
        0: begin FEdit.SelStart := 0; FEdit.SelLength := 2; end;
        1: begin FEdit.SelStart := 3; FEdit.SelLength := 2; end;
        2: begin FEdit.SelStart := 6; FEdit.SelLength := 4; end;
      end;
    dfMMYYYY:
      case ASegment of
        0: begin FEdit.SelStart := 0; FEdit.SelLength := 2; end;
        1: begin FEdit.SelStart := 3; FEdit.SelLength := 4; end;
      end;
  end;
end;

procedure TFRMaterialDateEdit.AdjustSegmentValue(ADelta: Integer);
var
  D, M, Y: Word;
  Seg: Integer;
begin
  if FDate < 1 then
  begin
    FDate := SysUtils.Date;
    RefreshDisplay;
  end;
  if FDate < 1 then Exit;

  Seg := GetCurrentSegment;
  DecodeDate(FDate, Y, M, D);

  case FDateFormat of
    dfDDMMYYYY:
      case Seg of
        0:
        begin
          D := D + ADelta;
          if D < 1 then D := 31;
          if D > 31 then D := 1;
        end;
        1:
        begin
          M := M + ADelta;
          if M < 1 then M := 12;
          if M > 12 then M := 1;
        end;
        2:
        begin
          Y := Y + ADelta;
          if Y < 1 then Y := 9999;
          if Y > 9999 then Y := 1;
        end;
      end;
    dfMMYYYY:
      case Seg of
        0:
        begin
          M := M + ADelta;
          if M < 1 then M := 12;
          if M > 12 then M := 1;
        end;
        1:
        begin
          Y := Y + ADelta;
          if Y < 1 then Y := 9999;
          if Y > 9999 then Y := 1;
        end;
      end;
  end;

  { Clamp day if it exceeds the valid range for the new month/year. }
  if D > DaysInAMonth(Y, M) then
    D := DaysInAMonth(Y, M);

  FDate := EncodeDate(Y, M, D);
  RefreshDisplay;
  SelectSegment(Seg);
end;

{ ── Calendar popup ── }

procedure TFRMaterialDateEdit.CalendarButtonClick(Sender: TObject);
var
  P: TPoint;
begin
  if FEdit.ReadOnly then Exit;

  if Assigned(FCalendarPopup) and FCalendarPopup.Visible then
  begin
    FCalendarPopup.Close;
    Exit;
  end;

  if not Assigned(FCalendarPopup) then
  begin
    FCalendarPopup := TForm.CreateNew(Self);
    FCalendarPopup.BorderStyle := bsNone;
    FCalendarPopup.FormStyle := fsStayOnTop;
    FCalendarPopup.Color := MD3Colors.OutlineVariant;
    FCalendarPopup.OnDeactivate := @CalendarPopupDeactivate;

    FCalendar := TFRMaterialDatePicker.Create(FCalendarPopup);
    FCalendar.Parent := FCalendarPopup;
    FCalendar.Align := alClient;
    FCalendar.BorderSpacing.Around := 1;  { 1px outline = form Color }
    FCalendar.OnChange := @CalendarDblClick;

    FCalendarPopup.Width := FCalendar.Width + 2;
    FCalendarPopup.Height := FCalendar.Height + 2;

    { Rounded corners — same technique as combo popup }
    {$IFDEF FPC}
    FCalendarPopup.HandleNeeded;
    {$IFDEF MSWINDOWS}
    { Region 2px larger than body on each side — BGRA antialiased
      edges are fully preserved, GDI region never clips smooth pixels }
    SetWindowRgn(FCalendarPopup.Handle,
      CreateRoundRectRgn(-2, -2, FCalendarPopup.Width + 3,
        FCalendarPopup.Height + 3, 12 * 2 + 6, 12 * 2 + 6), True);
    {$ENDIF}
    {$ENDIF}
  end;

  if FDate > 1 then
    FCalendar.Date := FDate
  else
    FCalendar.Date := Now;

  P := Self.ClientToScreen(Point(0, Self.Height));
  if P.X + FCalendarPopup.Width > Screen.Width then
    P.X := Screen.Width - FCalendarPopup.Width;
  if P.Y + FCalendarPopup.Height > Screen.Height then
    P.Y := P.Y - Self.Height - FCalendarPopup.Height;
  FCalendarPopup.Left := P.X;
  FCalendarPopup.Top  := P.Y;
  FCalendarPopup.Show;
end;

procedure TFRMaterialDateEdit.CalendarDblClick(Sender: TObject);
begin
  Date := FCalendar.Date;
  if Assigned(FCalendarPopup) then
    FCalendarPopup.Close;
  if FEdit.CanFocus then
    FEdit.SetFocus;
end;

procedure TFRMaterialDateEdit.CalendarPopupDeactivate(Sender: TObject);
begin
  if Assigned(FCalendarPopup) then
    FCalendarPopup.Close;
end;

{ ── Date property ── }

function TFRMaterialDateEdit.GetDate: TDateTime;
begin
  Result := FDate;
end;

procedure TFRMaterialDateEdit.SetDate(AValue: TDateTime);
begin
  if FDate = AValue then Exit;
  FDate := AValue;
  RefreshDisplay;
end;

procedure TFRMaterialDateEdit.SetDateFormat(AValue: TFRDateFormat);
begin
  if FDateFormat = AValue then Exit;
  FDateFormat := AValue;
  RefreshDisplay;
end;

procedure TFRMaterialDateEdit.ClearDate;
begin
  FDate := 0;
  FUpdating := True;
  try
    FEdit.Text := '';
  finally
    FUpdating := False;
  end;
end;

{ ── Layout / theme ── }

procedure TFRMaterialDateEdit.DoOnResize;
var
  BtnSize, CenterY, FieldH, BaseRight: Integer;
begin
  inherited DoOnResize;

  if not Assigned(FCalendarButton) then Exit;
  if csLoading in ComponentState then Exit;

  BtnSize := FEdit.Height - 2;
  if BtnSize < 20 then BtnSize := 20;
  FCalendarButton.Width  := BtnSize;
  FCalendarButton.Height := BtnSize;

  { Calendar is rightmost. Push all base right-panel buttons left
    by calendar width + gap, then position calendar at the edge. }
  FieldH := Self.Height;
  CenterY := (FieldH - BtnSize) div 2;
  if CenterY < 0 then CenterY := 0;

  { Shift base buttons left to make room for calendar }
  if ClearButton.Visible then
    ClearButton.BorderSpacing.Right := ClearButton.BorderSpacing.Right + BtnSize + 8;

  { Calendar at rightmost position }
  FCalendarButton.Anchors := [akRight];
  FCalendarButton.AnchorSide[akRight].Control := Self;
  FCalendarButton.AnchorSide[akRight].Side    := asrBottom;
  FCalendarButton.BorderSpacing.Right := 8;
  FCalendarButton.Top := CenterY;

  { Push FEdit to fit all buttons }
  FEdit.BorderSpacing.Right := FRightPanelWidth + BtnSize + 8;
end;

procedure TFRMaterialDateEdit.ApplyTheme(const AThemeManager: TObject);
begin
  inherited ApplyTheme(AThemeManager);
  if Assigned(FCalendarButton) then
  begin
    FCalendarButton.NormalColor := MD3Colors.OnSurfaceVariant;
    FCalendarButton.HoverColor  := MD3Colors.Primary;
    FCalendarButton.InvalidateCache;
  end;
  if Assigned(FCalendarPopup) then
    FCalendarPopup.Color := MD3Colors.OutlineVariant;
end;

end.
