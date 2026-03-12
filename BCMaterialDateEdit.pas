unit BCMaterialDateEdit;

{$mode objfpc}{$H+}

{ TBCMaterialDateEdit
  Componente de edição de data com estilo Material Design.
  Encapsula TDateEdit (LCL) com:
    - Label flutuante acima do campo (accentColor no foco)
    - Sublinhado Material Design
    - Botão de limpeza nativo opcional (ShowClearButton)
    - Acesso completo às propriedades/eventos do TDateEdit interno

  Requer: EditBtn, Calendar (LCL)
  Licença: LGPL v3 — mesma do bgracontrols
}

interface

uses
  Classes, Calendar, Controls, EditBtn, ExtCtrls, Forms, Graphics,
  {$IFDEF FPC} LCLType, LResources, {$ENDIF} Menus, StdCtrls, SysUtils;

type

  { TBCMaterialDateEdit }

  TBCMaterialDateEdit = class(TCustomPanel)
  private
    FAccentColor: TColor;
    FDisabledColor: TColor;
    FLabel: TBoundLabel;
    FDateEdit: TDateEdit;
    FFocused: Boolean;
    FClearButton: TButton;
    FShowClearButton: Boolean;
    FOnClearButtonClick: TNotifyEvent;
    { Armazena OnChange do usuário; FDateEdit.OnChange é reservado para uso interno }
    FUserOnChange: TNotifyEvent;

    function IsNeededAdjustSize: Boolean;

    { Botão de limpeza }
    function GetShowClearButton: Boolean;
    procedure SetShowClearButton(AValue: Boolean);
    procedure ClearButtonClick(Sender: TObject);
    procedure InternalDateEditChange(Sender: TObject);
    procedure UpdateClearButton;

    { Propriedades de TDateEdit }
    function GetCalendarDisplaySettings: TDisplaySettings;
    procedure SetCalendarDisplaySettings(AValue: TDisplaySettings);
    function GetDate: TDateTime;
    procedure SetDate(AValue: TDateTime);
    function GetDateOrder: TDateOrder;
    procedure SetDateOrder(AValue: TDateOrder);
    function GetDirectInput: Boolean;
    procedure SetDirectInput(AValue: Boolean);
    function GetEditCursor: TCursor;
    procedure SetEditCursor(AValue: TCursor);
    function GetEditPopupMenu: TPopupMenu;
    procedure SetEditPopupMenu(AValue: TPopupMenu);
    function GetEditReadOnly: Boolean;
    procedure SetEditReadOnly(AValue: Boolean);
    function GetEditTabStop: Boolean;
    procedure SetEditTabStop(AValue: Boolean);
    function GetEditText: TCaption;
    procedure SetEditText(const AValue: TCaption);
    function GetEditTextHint: TTranslateString;
    procedure SetEditTextHint(const AValue: TTranslateString);
    function GetLabelCaption: TCaption;
    procedure SetLabelCaption(const AValue: TCaption);
    function GetLabelSpacing: Integer;
    procedure SetLabelSpacing(AValue: Integer);

    { Eventos de TDateEdit }
    function GetOnAcceptDate: TAcceptDateEvent;
    procedure SetOnAcceptDate(AValue: TAcceptDateEvent);
    function GetOnChange: TNotifyEvent;
    procedure SetOnChange(AValue: TNotifyEvent);
    function GetOnClick: TNotifyEvent;
    procedure SetOnClick(AValue: TNotifyEvent);
    function GetOnCustomDate: TCustomDateEvent;
    procedure SetOnCustomDate(AValue: TCustomDateEvent);
    function GetOnEditingDone: TNotifyEvent;
    procedure SetOnEditingDone(AValue: TNotifyEvent);
    function GetOnEnter: TNotifyEvent;
    procedure SetOnEnter(AValue: TNotifyEvent);
    function GetOnExit: TNotifyEvent;
    procedure SetOnExit(AValue: TNotifyEvent);
    function GetOnKeyDown: TKeyEvent;
    procedure SetOnKeyDown(AValue: TKeyEvent);
    function GetOnKeyPress: TKeyPressEvent;
    procedure SetOnKeyPress(AValue: TKeyPressEvent);
    function GetOnKeyUp: TKeyEvent;
    procedure SetOnKeyUp(AValue: TKeyEvent);
    function GetOnUTF8KeyPress: TUTF8KeyPressEvent;
    procedure SetOnUTF8KeyPress(AValue: TUTF8KeyPressEvent);

  protected
    procedure SetAnchors(const AValue: TAnchors); override;
    procedure SetColor(AValue: TColor); override;
    procedure SetName(const AValue: TComponentName); override;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure DoOnResize; override;
    procedure Paint; override;

  public
    constructor Create(AOwner: TComponent); override;
    { Limpa o campo de data }
    procedure ClearDate;
    { Acesso direto ao TDateEdit interno para customizações avançadas }
    property DateEdit: TDateEdit read FDateEdit;
    { Acesso ao botão de limpeza (caption, hint, cor etc.) }
    property ClearButton: TButton read FClearButton;

  published
    property Align;
    property AccentColor: TColor read FAccentColor write FAccentColor;
    property Anchors;
    property BiDiMode;
    property BorderSpacing;
    { Configurações de exibição do calendário popup }
    property CalendarDisplaySettings: TDisplaySettings
      read GetCalendarDisplaySettings write SetCalendarDisplaySettings;
    { Legenda do label flutuante }
    property Caption: TCaption read GetLabelCaption write SetLabelCaption;
    property Color;
    property Constraints;
    property Cursor: TCursor read GetEditCursor write SetEditCursor default crDefault;
    { Data selecionada (TDateTime) }
    property Date: TDateTime read GetDate write SetDate;
    { Ordem de exibição da data (DMY, MDY, YMD, nativa, nenhuma) }
    property DateOrder: TDateOrder read GetDateOrder write SetDateOrder default doNone;
    { Permite digitação direta; False = somente via calendário }
    property DirectInput: Boolean read GetDirectInput write SetDirectInput default True;
    property DisabledColor: TColor read FDisabledColor write FDisabledColor;
    { Label flutuante acima do campo }
    property EditLabel: TBoundLabel read FLabel;
    property Enabled;
    property Font;
    property Hint;
    property LabelSpacing: Integer read GetLabelSpacing write SetLabelSpacing default 4;
    property ParentBiDiMode;
    property ParentColor default False;
    property ParentFont default False;
    property PopupMenu: TPopupMenu read GetEditPopupMenu write SetEditPopupMenu;
    property ReadOnly: Boolean read GetEditReadOnly write SetEditReadOnly default False;
    { Exibe botão "×" quando o campo tiver data e não estiver em ReadOnly }
    property ShowClearButton: Boolean
      read GetShowClearButton write SetShowClearButton default False;
    property ShowHint;
    property TabOrder;
    property TabStop: Boolean read GetEditTabStop write SetEditTabStop default True;
    { Texto bruto do campo (use Date para obter TDateTime) }
    property Text: TCaption read GetEditText write SetEditText;
    property TextHint: TTranslateString read GetEditTextHint write SetEditTextHint;
    property Visible;

    { Disparado quando o usuário confirma uma data no calendário }
    property OnAcceptDate: TAcceptDateEvent read GetOnAcceptDate write SetOnAcceptDate;
    property OnChange: TNotifyEvent read GetOnChange write SetOnChange;
    property OnChangeBounds;
    { Disparado após clicar no botão de limpeza (campo já foi limpo) }
    property OnClearButtonClick: TNotifyEvent
      read FOnClearButtonClick write FOnClearButtonClick;
    property OnClick: TNotifyEvent read GetOnClick write SetOnClick;
    { Disparado quando o usuário escolhe "data personalizada" no calendário }
    property OnCustomDate: TCustomDateEvent read GetOnCustomDate write SetOnCustomDate;
    property OnEditingDone: TNotifyEvent read GetOnEditingDone write SetOnEditingDone;
    property OnEnter: TNotifyEvent read GetOnEnter write SetOnEnter;
    property OnExit: TNotifyEvent read GetOnExit write SetOnExit;
    property OnKeyDown: TKeyEvent read GetOnKeyDown write SetOnKeyDown;
    property OnKeyPress: TKeyPressEvent read GetOnKeyPress write SetOnKeyPress;
    property OnKeyUp: TKeyEvent read GetOnKeyUp write SetOnKeyUp;
    property OnResize;
    property OnUTF8KeyPress: TUTF8KeyPressEvent
      read GetOnUTF8KeyPress write SetOnUTF8KeyPress;
  end;

procedure Register;

implementation

procedure Register;
begin
  {$IFDEF FPC}
    { Descomente e adicione o ícone quando disponível:
      {$I icons\bcmaterialdateedit_icon.lrs} }
  {$ENDIF}
  RegisterComponents('BGRA Controls', [TBCMaterialDateEdit]);
end;

{ TBCMaterialDateEdit }

function TBCMaterialDateEdit.IsNeededAdjustSize: Boolean;
begin
  if (Self.Align in [alLeft, alRight, alClient]) then Exit(False);
  if (akTop in Self.Anchors) and (akBottom in Self.Anchors) then Exit(False);
  Result := True; { TDateEdit tem altura fixa (AutoSize implícito) }
end;

{ --- Botão de limpeza --- }

function TBCMaterialDateEdit.GetShowClearButton: Boolean;
begin
  Result := FShowClearButton;
end;

procedure TBCMaterialDateEdit.SetShowClearButton(AValue: Boolean);
begin
  if FShowClearButton = AValue then Exit;
  FShowClearButton := AValue;
  UpdateClearButton;
end;

procedure TBCMaterialDateEdit.ClearButtonClick(Sender: TObject);
begin
  ClearDate;
  FDateEdit.SetFocus;
  if Assigned(FOnClearButtonClick) then
    FOnClearButtonClick(Self);
end;

procedure TBCMaterialDateEdit.InternalDateEditChange(Sender: TObject);
begin
  UpdateClearButton;
  if Assigned(FUserOnChange) then
    FUserOnChange(Sender);
end;

procedure TBCMaterialDateEdit.UpdateClearButton;
var
  ShouldShow: Boolean;
begin
  ShouldShow := FShowClearButton
    and (FDateEdit.Text <> '')
    and not FDateEdit.ReadOnly;

  if ShouldShow = FClearButton.Visible then Exit;

  DisableAlign;
  try
    FClearButton.Visible := ShouldShow;
    { Abre/fecha espaço no lado direito para o botão }
    if ShouldShow then
      FDateEdit.BorderSpacing.Right := FClearButton.Width + 4
    else
      FDateEdit.BorderSpacing.Right := 4;
  finally
    EnableAlign;
  end;
  Invalidate;
end;

procedure TBCMaterialDateEdit.ClearDate;
begin
  FDateEdit.Text := '';
end;

{ --- Getters/Setters de propriedades --- }

function TBCMaterialDateEdit.GetCalendarDisplaySettings: TDisplaySettings;
begin
  Result := FDateEdit.CalendarDisplaySettings;
end;

procedure TBCMaterialDateEdit.SetCalendarDisplaySettings(AValue: TDisplaySettings);
begin
  FDateEdit.CalendarDisplaySettings := AValue;
end;

function TBCMaterialDateEdit.GetDate: TDateTime;
begin
  Result := FDateEdit.Date;
end;

procedure TBCMaterialDateEdit.SetDate(AValue: TDateTime);
begin
  FDateEdit.Date := AValue;
end;

function TBCMaterialDateEdit.GetDateOrder: TDateOrder;
begin
  Result := FDateEdit.DateOrder;
end;

procedure TBCMaterialDateEdit.SetDateOrder(AValue: TDateOrder);
begin
  FDateEdit.DateOrder := AValue;
end;

function TBCMaterialDateEdit.GetDirectInput: Boolean;
begin
  Result := FDateEdit.DirectInput;
end;

procedure TBCMaterialDateEdit.SetDirectInput(AValue: Boolean);
begin
  FDateEdit.DirectInput := AValue;
end;

function TBCMaterialDateEdit.GetEditCursor: TCursor;
begin
  Result := FDateEdit.Cursor;
end;

procedure TBCMaterialDateEdit.SetEditCursor(AValue: TCursor);
begin
  FDateEdit.Cursor := AValue;
end;

function TBCMaterialDateEdit.GetEditPopupMenu: TPopupMenu;
begin
  if csDestroying in ComponentState then Exit(nil);
  Result := FDateEdit.PopupMenu;
end;

procedure TBCMaterialDateEdit.SetEditPopupMenu(AValue: TPopupMenu);
begin
  FDateEdit.PopupMenu := AValue;
end;

function TBCMaterialDateEdit.GetEditReadOnly: Boolean;
begin
  Result := FDateEdit.ReadOnly;
end;

procedure TBCMaterialDateEdit.SetEditReadOnly(AValue: Boolean);
begin
  FDateEdit.ReadOnly := AValue;
  UpdateClearButton;
end;

function TBCMaterialDateEdit.GetEditTabStop: Boolean;
begin
  Result := FDateEdit.TabStop;
end;

procedure TBCMaterialDateEdit.SetEditTabStop(AValue: Boolean);
begin
  FDateEdit.TabStop := AValue;
end;

function TBCMaterialDateEdit.GetEditText: TCaption;
begin
  Result := FDateEdit.Text;
end;

procedure TBCMaterialDateEdit.SetEditText(const AValue: TCaption);
begin
  FDateEdit.Text := AValue;
end;

function TBCMaterialDateEdit.GetEditTextHint: TTranslateString;
begin
  Result := FDateEdit.TextHint;
end;

procedure TBCMaterialDateEdit.SetEditTextHint(const AValue: TTranslateString);
begin
  FDateEdit.TextHint := AValue;
end;

function TBCMaterialDateEdit.GetLabelCaption: TCaption;
begin
  Result := FLabel.Caption;
end;

procedure TBCMaterialDateEdit.SetLabelCaption(const AValue: TCaption);
begin
  FLabel.Caption := AValue;
end;

function TBCMaterialDateEdit.GetLabelSpacing: Integer;
begin
  Result := FLabel.BorderSpacing.Bottom;
end;

procedure TBCMaterialDateEdit.SetLabelSpacing(AValue: Integer);
begin
  if FLabel.BorderSpacing.Bottom = AValue then Exit;
  FLabel.BorderSpacing.Bottom := AValue;
  if not (csLoading in ComponentState) then Self.DoOnResize;
end;

{ --- Getters/Setters de eventos --- }

function TBCMaterialDateEdit.GetOnAcceptDate: TAcceptDateEvent;
begin
  Result := FDateEdit.OnAcceptDate;
end;

procedure TBCMaterialDateEdit.SetOnAcceptDate(AValue: TAcceptDateEvent);
begin
  FDateEdit.OnAcceptDate := AValue;
end;

{ OnChange é interceptado internamente para controlar o botão de limpeza.
  O handler do usuário é armazenado em FUserOnChange e chamado dentro de
  InternalDateEditChange. }
function TBCMaterialDateEdit.GetOnChange: TNotifyEvent;
begin
  Result := FUserOnChange;
end;

procedure TBCMaterialDateEdit.SetOnChange(AValue: TNotifyEvent);
begin
  FUserOnChange := AValue;
end;

function TBCMaterialDateEdit.GetOnClick: TNotifyEvent;
begin
  Result := FDateEdit.OnClick;
end;

procedure TBCMaterialDateEdit.SetOnClick(AValue: TNotifyEvent);
begin
  FDateEdit.OnClick := AValue;
end;

function TBCMaterialDateEdit.GetOnCustomDate: TCustomDateEvent;
begin
  Result := FDateEdit.OnCustomDate;
end;

procedure TBCMaterialDateEdit.SetOnCustomDate(AValue: TCustomDateEvent);
begin
  FDateEdit.OnCustomDate := AValue;
end;

function TBCMaterialDateEdit.GetOnEditingDone: TNotifyEvent;
begin
  Result := FDateEdit.OnEditingDone;
end;

procedure TBCMaterialDateEdit.SetOnEditingDone(AValue: TNotifyEvent);
begin
  FDateEdit.OnEditingDone := AValue;
end;

function TBCMaterialDateEdit.GetOnEnter: TNotifyEvent;
begin
  Result := FDateEdit.OnEnter;
end;

procedure TBCMaterialDateEdit.SetOnEnter(AValue: TNotifyEvent);
begin
  FDateEdit.OnEnter := AValue;
end;

function TBCMaterialDateEdit.GetOnExit: TNotifyEvent;
begin
  Result := FDateEdit.OnExit;
end;

procedure TBCMaterialDateEdit.SetOnExit(AValue: TNotifyEvent);
begin
  FDateEdit.OnExit := AValue;
end;

function TBCMaterialDateEdit.GetOnKeyDown: TKeyEvent;
begin
  Result := FDateEdit.OnKeyDown;
end;

procedure TBCMaterialDateEdit.SetOnKeyDown(AValue: TKeyEvent);
begin
  FDateEdit.OnKeyDown := AValue;
end;

function TBCMaterialDateEdit.GetOnKeyPress: TKeyPressEvent;
begin
  Result := FDateEdit.OnKeyPress;
end;

procedure TBCMaterialDateEdit.SetOnKeyPress(AValue: TKeyPressEvent);
begin
  FDateEdit.OnKeyPress := AValue;
end;

function TBCMaterialDateEdit.GetOnKeyUp: TKeyEvent;
begin
  Result := FDateEdit.OnKeyUp;
end;

procedure TBCMaterialDateEdit.SetOnKeyUp(AValue: TKeyEvent);
begin
  FDateEdit.OnKeyUp := AValue;
end;

function TBCMaterialDateEdit.GetOnUTF8KeyPress: TUTF8KeyPressEvent;
begin
  Result := FDateEdit.OnUTF8KeyPress;
end;

procedure TBCMaterialDateEdit.SetOnUTF8KeyPress(AValue: TUTF8KeyPressEvent);
begin
  FDateEdit.OnUTF8KeyPress := AValue;
end;

{ --- Métodos protegidos --- }

procedure TBCMaterialDateEdit.SetAnchors(const AValue: TAnchors);
begin
  if Self.Anchors = AValue then Exit;
  inherited SetAnchors(AValue);
  if not (csLoading in ComponentState) then Self.DoOnResize;
end;

procedure TBCMaterialDateEdit.SetColor(AValue: TColor);
begin
  inherited SetColor(AValue);
  FDateEdit.Color := AValue;
end;

procedure TBCMaterialDateEdit.SetName(const AValue: TComponentName);
begin
  if csDesigning in ComponentState then
  begin
    if (FLabel.Caption = '') or AnsiSameText(FLabel.Caption, Name) then
      FLabel.Caption := 'Data';
    if (FLabel.Name = '') or AnsiSameText(FLabel.Name, Name) then
      FLabel.Name := AValue + 'SubLabel';
    if (FDateEdit.Name = '') or AnsiSameText(FDateEdit.Name, Name) then
      FDateEdit.Name := AValue + 'SubDateEdit';
  end;
  inherited SetName(AValue);
end;

procedure TBCMaterialDateEdit.DoEnter;
begin
  inherited DoEnter;
  FFocused := True;
  Invalidate;
end;

procedure TBCMaterialDateEdit.DoExit;
begin
  FFocused := False;
  Invalidate;
  inherited DoExit;
end;

procedure TBCMaterialDateEdit.DoOnResize;
var
  AutoSizedHeight: LongInt;
begin
  if IsNeededAdjustSize then
  begin
    FDateEdit.Align := alBottom;
    AutoSizedHeight :=
      FLabel.Height +
      FLabel.BorderSpacing.Around +
      FLabel.BorderSpacing.Bottom +
      FLabel.BorderSpacing.Top +
      FDateEdit.Height +
      FDateEdit.BorderSpacing.Around +
      FDateEdit.BorderSpacing.Bottom +
      FDateEdit.BorderSpacing.Top;

    if Self.Height <> AutoSizedHeight then
      Self.Height := AutoSizedHeight;
  end else
    FDateEdit.Align := alClient;

  { Posiciona o botão de limpeza à direita do campo de data,
    antes do botão de calendário nativo do TDateEdit }
  if Assigned(FClearButton) and FClearButton.Visible then
  begin
    FClearButton.Height := FDateEdit.Height - 2;
    FClearButton.Left   := FDateEdit.Left + FDateEdit.Width + 2;
    FClearButton.Top    :=
      FDateEdit.Top + (FDateEdit.Height - FClearButton.Height) div 2;
    FClearButton.BringToFront;
  end;

  inherited DoOnResize;
end;

procedure TBCMaterialDateEdit.Paint;
var
  LeftPos, RightPos: Integer;
begin
  inherited Paint;
  Canvas.Brush.Color := Color;
  Canvas.Pen.Color := Color;
  Canvas.Rectangle(0, 0, Width, Height);

  if Assigned(Parent) and (Parent.Color = Color) then
  begin
    LeftPos := FDateEdit.Left;
    if FClearButton.Visible then
      RightPos := FClearButton.Left + FClearButton.Width
    else
      RightPos := FDateEdit.Left + FDateEdit.Width;
  end else
  begin
    LeftPos := 0;
    RightPos := Width;
  end;

  if FFocused and Self.Enabled then
  begin
    Canvas.Pen.Color := AccentColor;
    Canvas.Line(LeftPos, Height - 2, RightPos, Height - 2);
    Canvas.Line(LeftPos, Height - 1, RightPos, Height - 1);
    FLabel.Font.Color := AccentColor;
  end else
  begin
    Canvas.Pen.Color := DisabledColor;
    Canvas.Line(LeftPos, Height - 1, RightPos, Height - 1);
    FLabel.Font.Color := DisabledColor;
  end;
end;

constructor TBCMaterialDateEdit.Create(AOwner: TComponent);
begin
  FDateEdit := TDateEdit.Create(Self);
  FLabel    := TBoundLabel.Create(Self);
  inherited Create(AOwner);

  Self.AccentColor  := clHighlight;
  Self.BorderStyle  := bsNone;
  Self.Color        := clWindow;
  Self.DisabledColor := $00B8AFA8;
  Self.ParentColor  := False;

  FLabel.Align                  := alTop;
  FLabel.AutoSize               := True;
  FLabel.BorderSpacing.Around   := 0;
  FLabel.BorderSpacing.Bottom   := 4;
  FLabel.BorderSpacing.Left     := 4;
  FLabel.BorderSpacing.Right    := 4;
  FLabel.BorderSpacing.Top      := 4;
  FLabel.Font.Color             := $00B8AFA8;
  FLabel.Font.Style             := [fsBold];
  FLabel.Parent                 := Self;
  FLabel.ParentFont             := False;
  FLabel.ParentBiDiMode         := True;
  FLabel.SetSubComponent(True);

  FDateEdit.Align                := alBottom;
  FDateEdit.BorderSpacing.Around := 0;
  FDateEdit.BorderSpacing.Bottom := 4;
  FDateEdit.BorderSpacing.Left   := 4;
  FDateEdit.BorderSpacing.Right  := 4;
  FDateEdit.BorderSpacing.Top    := 0;
  FDateEdit.Color                := Color;
  FDateEdit.Parent               := Self;
  FDateEdit.ParentFont           := True;
  FDateEdit.ParentBiDiMode       := True;
  FDateEdit.TabStop              := True;
  FDateEdit.SetSubComponent(True);

  { Intercepta OnChange para controlar visibilidade do botão de limpeza.
    O OnChange que o usuário definir é armazenado em FUserOnChange e
    chamado dentro de InternalDateEditChange. }
  FDateEdit.OnChange := @InternalDateEditChange;

  { Botão de limpeza }
  FClearButton          := TButton.Create(Self);
  FClearButton.Caption  := '×';      { × U+00D7 }
  FClearButton.Width    := 22;
  FClearButton.Height   := 22;
  FClearButton.TabStop  := False;
  FClearButton.Visible  := False;
  FClearButton.Parent   := Self;
  FClearButton.OnClick  := @ClearButtonClick;
  FClearButton.SetSubComponent(True);

  FShowClearButton := False;
end;

end.
