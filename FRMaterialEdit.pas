unit FRMaterialEdit;

{$mode objfpc}{$H+}

interface

uses
  FRMaterialTheme, Buttons, Classes, Controls, Dialogs, ExtCtrls, Forms, Graphics,
  {$IFDEF FPC} LCLType, LResources, {$ENDIF} Menus, StdCtrls, SysUtils;

type

  { TFRMaterialEditBase }

  generic TFRMaterialEditBase<T> = class(TCustomPanel)
  private
    FAccentColor: TColor;
    FDisabledColor: TColor;
    FLabel: TBoundLabel;
    FFocused: boolean;
    FClearButton: TButton;
    FShowClearButton: Boolean;
    FOnClearButtonClick: TNotifyEvent;
    FSearchButton: TBitBtn;
    FShowSearchButton: Boolean;
    FOnSearchButtonClick: TNotifyEvent;
    FVariant: TFRMaterialVariant;
    FBorderRadius: Integer;

    function IsNeededAdjustSize: boolean;

    function GetShowClearButton: Boolean;
    procedure SetShowClearButton(AValue: Boolean);
    procedure ClearButtonClick(Sender: TObject);
    procedure InternalEditChange(Sender: TObject);
    procedure UpdateClearButton;
    procedure UpdateRightButtonSpacing;
    function GetShowSearchButton: Boolean;
    procedure SetShowSearchButton(AValue: Boolean);
    procedure SearchButtonClick(Sender: TObject);
    procedure DrawSearchIcon(AColor: TColor);

    function GetOnEditChange: TNotifyEvent;
    function GetOnEditClick: TNotifyEvent;
    function GetOnEditEditingDone: TNotifyEvent;
    function GetOnEditEnter: TNotifyEvent;
    function GetOnEditExit: TNotifyEvent;
    function GetOnEditKeyDown: TKeyEvent;
    function GetOnEditKeyPress: TKeyPressEvent;
    function GetOnEditKeyUp: TKeyEvent;
    function GetOnEditMouseDown: TMouseEvent;
    function GetOnEditMouseEnter: TNotifyEvent;
    function GetOnEditMouseLeave: TNotifyEvent;
    function GetOnEditMouseMove: TMouseMoveEvent;
    function GetOnEditMouseUp: TMouseEvent;
    function GetOnEditMouseWheel: TMouseWheelEvent;
    function GetOnEditMouseWheelDown: TMouseWheelUpDownEvent;
    function GetOnEditMouseWheelUp: TMouseWheelUpDownEvent;
    function GetOnEditUTF8KeyPress: TUTF8KeyPressEvent;

    procedure SetOnEditChange(AValue: TNotifyEvent);
    procedure SetOnEditClick(AValue: TNotifyEvent);
    procedure SetOnEditEditingDone(AValue: TNotifyEvent);
    procedure SetOnEditEnter(AValue: TNotifyEvent);
    procedure SetOnEditExit(AValue: TNotifyEvent);
    procedure SetOnEditKeyDown(AValue: TKeyEvent);
    procedure SetOnEditKeyPress(AValue: TKeyPressEvent);
    procedure SetOnEditKeyUp(AValue: TKeyEvent);
    procedure SetOnEditMouseDown(AValue: TMouseEvent);
    procedure SetOnEditMouseEnter(AValue: TNotifyEvent);
    procedure SetOnEditMouseLeave(AValue: TNotifyEvent);
    procedure SetOnEditMouseMove(AValue: TMouseMoveEvent);
    procedure SetOnEditMouseUp(AValue: TMouseEvent);
    procedure SetOnEditMouseWheel(AValue: TMouseWheelEvent);
    procedure SetOnEditMouseWheelDown(AValue: TMouseWheelUpDownEvent);
    procedure SetOnEditMouseWheelUp(AValue: TMouseWheelUpDownEvent);
    procedure SetOnEditUTF8KeyPress(AValue: TUTF8KeyPressEvent);
  protected
    FEdit: T;

    function GetEditAlignment: TAlignment;
    function GetEditAutoSize: Boolean;
    function GetEditAutoSelect: Boolean;
    function GetEditCharCase: TEditCharCase;
    function GetEditCursor: TCursor;
    function GetEditDoubleBuffered: Boolean;
    function GetEditEchoMode: TEchoMode;
    function GetEditHideSelection: Boolean;
    function GetEditHint: TTranslateString;
    function GetEditMaxLength: Integer;
    function GetEditNumbersOnly: Boolean;
    function GetEditPasswordChar: Char;
    function GetEditParentColor: Boolean;
    function GetEditPopupMenu: TPopupMenu;
    function GetEditReadOnly: Boolean;
    function GetEditShowHint: Boolean;
    function GetEditTag: PtrInt;
    function GetEditTabStop: Boolean;
    function GetEditText: TCaption;
    function GetEditTextHint: TTranslateString;
    function GetLabelCaption: TCaption;
    function GetLabelSpacing: Integer;

    procedure SetAnchors(const AValue: TAnchors); override;
    procedure SetColor(AValue: TColor); override;
    procedure SetEditAlignment(const AValue: TAlignment);
    procedure SetEditAutoSize(AValue: Boolean);
    procedure SetEditAutoSelect(AValue: Boolean);
    procedure SetEditCharCase(AValue: TEditCharCase);
    procedure SetEditCursor(AValue: TCursor);
    procedure SetEditDoubleBuffered(AValue: Boolean);
    procedure SetEditEchoMode(AValue: TEchoMode);
    procedure SetEditHideSelection(AValue: Boolean);
    procedure SetEditHint(const AValue: TTranslateString);
    procedure SetEditMaxLength(AValue: Integer);
    procedure SetEditNumbersOnly(AValue: Boolean);
    procedure SetEditParentColor(AValue: Boolean);
    procedure SetEditPasswordChar(AValue: Char);
    procedure SetEditPopupMenu(AValue: TPopupmenu);
    procedure SetEditReadOnly(AValue: Boolean);
    procedure SetEditShowHint(AValue: Boolean);
    procedure SetEditTag(AValue: PtrInt);
    procedure SetEditTabStop(AValue: Boolean);
    procedure SetEditText(const AValue: TCaption);
    procedure SetEditTextHint(const Avalue: TTranslateString);
    procedure SetLabelCaption(const AValue: TCaption);
    procedure SetLabelSpacing(AValue: Integer);
    procedure SetName(const AValue: TComponentName); override;

    procedure DoEnter; override;
    procedure DoExit; override;
    procedure DoOnResize; override;
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    { Expõe o botão de limpeza para customização visual (caption, hint, font, etc.) }
    property ClearButton: TButton read FClearButton;
    { Expõe o botão de pesquisa para customização visual (hint, glyph, etc.) }
    property SearchButton: TBitBtn read FSearchButton;
  published
    property Align;
    property Alignment: TAlignment read GetEditAlignment write SetEditAlignment default taLeftJustify;
    property AccentColor: TColor read FAccentColor write FAccentColor;
    property Anchors;
    property AutoSelect: Boolean read GetEditAutoSelect write SetEditAutoSelect default True;
    property AutoSize: Boolean read GetEditAutoSize write SetEditAutoSize default True;
    property BiDiMode;
    property BorderSpacing;
    property Caption: TCaption read GetLabelCaption write SetLabelCaption;
    property CharCase: TEditCharCase read GetEditCharCase write SetEditCharCase default ecNormal;
    property Color;
    property Constraints;
    property Cursor: TCursor read GetEditCursor write SetEditCursor default crDefault;
    property DisabledColor: TColor read FDisabledColor write FDisabledColor;
    property DoubleBuffered: Boolean read GetEditDoubleBuffered write SetEditDoubleBuffered;
    property EchoMode: TEchoMode read GetEditEchoMode write SetEditEchoMode default emNormal;
    property EditLabel: TBoundLabel read FLabel;
    property Enabled;
    property Font;
    property HideSelection: Boolean read GetEditHideSelection write SetEditHideSelection default True;
    property Hint: TTranslateString read GetEditHint write SetEditHint;
    property LabelSpacing: Integer read GetLabelSpacing write SetLabelSpacing default 4;
    property MaxLength: Integer read GetEditMaxLength write SetEditMaxLength default 0;
    property NumbersOnly: Boolean read GetEditNumbersOnly write SetEditNumbersOnly default False;
    property ParentBiDiMode;
    property ParentColor default False;
    property ParentFont default False;
    property PasswordChar: Char read GetEditPasswordChar write SetEditPasswordChar default #0;
    property PopupMenu: TPopupmenu read GetEditPopupMenu write SetEditPopupMenu;
    property ReadOnly: Boolean read GetEditReadOnly write SetEditReadOnly default False;
    { Quando True, exibe um botão "×" à direita do campo ao digitar texto }
    property ShowClearButton: Boolean read GetShowClearButton write SetShowClearButton default False;
    { Quando True, exibe um botão com ícone de lupa à direita do campo }
    property ShowSearchButton: Boolean read GetShowSearchButton write SetShowSearchButton default False;
    { Variante visual: sublinhado (mvStandard), preenchido (mvFilled) ou contornado (mvOutlined) }
    property Variant: TFRMaterialVariant read FVariant write FVariant default mvStandard;
    { Raio dos cantos arredondados em pixels; 0 = cantos retos }
    property BorderRadius: Integer read FBorderRadius write FBorderRadius default 0;
    property ShowHint: Boolean read GetEditShowHint write SetEditShowHint default False;
    property Tag: PtrInt read GetEditTag write SetEditTag default 0;
    property TabOrder;
    property TabStop: boolean read GetEditTabStop write SetEditTabStop default True;
    property Text: TCaption read GetEditText write SetEditText;
    property TextHint: TTranslateString read GetEditTextHint write SetEditTextHint;
    property Visible;

    property OnChange: TNotifyEvent read GetOnEditChange write SetOnEditChange;
    property OnChangeBounds;
    { Disparado após o usuário clicar no botão de limpeza }
    property OnClearButtonClick: TNotifyEvent read FOnClearButtonClick write FOnClearButtonClick;
    property OnClick: TNotifyEvent read GetOnEditClick write SetOnEditClick;
    property OnEditingDone: TNotifyEvent read GetOnEditEditingDone write SetOnEditEditingDone;
    property OnEnter: TNotifyEvent read GetOnEditEnter write SetOnEditEnter;
    property OnExit: TNotifyEvent read GetOnEditExit write SetOnEditExit;
    property OnKeyDown: TKeyEvent read GetOnEditKeyDown write SetOnEditKeyDown;
    property OnKeyPress: TKeyPressEvent read GetOnEditKeyPress write SetOnEditKeyPress;
    property OnKeyUp: TKeyEvent read GetOnEditKeyUp write SetOnEditKeyUp;
    property OnMouseDown: TMouseEvent read GetOnEditMouseDown write SetOnEditMouseDown;
    property OnMouseEnter: TNotifyEvent read GetOnEditMouseEnter write SetOnEditMouseEnter;
    property OnMouseLeave: TNotifyEvent read GetOnEditMouseLeave write SetOnEditMouseLeave;
    property OnMouseMove: TMouseMoveEvent read GetOnEditMouseMove write SetOnEditMouseMove;
    property OnMouseUp: TMouseEvent read GetOnEditMouseUp write SetOnEditMouseUp;
    property OnMouseWheel: TMouseWheelEvent read GetOnEditMouseWheel write SetOnEditMouseWheel;
    property OnMouseWheelDown: TMouseWheelUpDownEvent read GetOnEditMouseWheelDown write SetOnEditMouseWheelDown;
    property OnMouseWheelUp: TMouseWheelUpDownEvent read GetOnEditMouseWheelUp write SetOnEditMouseWheelUp;
    property OnResize;
    property OnUTF8KeyPress: TUTF8KeyPressEvent read GetOnEditUTF8KeyPress write SetOnEditUTF8KeyPress;
  end;

  { TFRMaterialEdit }

  TFRMaterialEdit = class(specialize TFRMaterialEditBase<TEdit>)
  private
    function GetEditDragCursor: TCursor;
    function GetEditDragMode: TDragMode;

    function GetOnEditContextPopup: TContextPopupEvent;
    function GetOnEditDblClick: TNotifyEvent;
    function GetOnEditDragDrop: TDragDropEvent;
    function GetOnEditDragOver: TDragOverEvent;
    function GetOnEditEndDrag: TEndDragEvent;
    function GetOnEditStartDrag: TStartDragEvent;

    procedure SetEditDragCursor(AValue: TCursor);
    procedure SetEditDragMode(AValue: TDragMode);

    procedure SetOnEditContextPopup(AValue: TContextPopupEvent);
    procedure SetOnEditDblClick(AValue: TNotifyEvent);
    procedure SetOnEditDragDrop(AValue: TDragDropEvent);
    procedure SetOnEditDragOver(AValue: TDragOverEvent);
    procedure SetOnEditEndDrag(AValue: TEndDragEvent);
    procedure SetOnEditStartDrag(AValue: TStartDragEvent);
  published
    property Align;
    property Alignment;
    property AccentColor;
    property Anchors;
    property AutoSelect;
    property AutoSize;
    property BiDiMode;
    property BorderSpacing;
    property Caption;
    property CharCase;
    property Color;
    property Constraints;
    property Cursor;
    property DisabledColor;
    property DoubleBuffered;
    property DragCursor: TCursor read GetEditDragCursor write SetEditDragCursor default crDrag;
    property DragMode: TDragMode read GetEditDragMode write SetEditDragMode default dmManual;
    property Font;
    property EchoMode;
    property Edit: TEdit read FEdit;
    property EditLabel;
    property Enabled;
    property HideSelection;
    property Hint;
    property LabelSpacing;
    property MaxLength;
    property NumbersOnly;
    property ParentBiDiMode;
    property ParentColor;
    property ParentFont;
    property PasswordChar;
    property PopupMenu;
    property ReadOnly;
    property ShowClearButton;
    property ShowSearchButton: Boolean read GetShowSearchButton write SetShowSearchButton default False;
    property Variant;
    property BorderRadius;
    property ShowHint;
    property Tag;
    property TabOrder;
    property TabStop;
    property Text;
    property TextHint;
    property Visible;

    property OnChange;
    property OnChangeBounds;
    property OnClearButtonClick;
    property OnSearchButtonClick: TNotifyEvent read FOnSearchButtonClick write FOnSearchButtonClick;
    property OnClick;
    property OnContextPopup;
    property OnDbClick: TNotifyEvent read GetOnEditDblClick write SetOnEditDblClick;
    property OnDragDrop: TDragDropEvent read GetOnEditDragDrop write SetOnEditDragDrop;
    property OnDragOver: TDragOverEvent read GetOnEditDragOver write SetOnEditDragOver;
    property OnEditingDone;
    property OnEndDrag: TEndDragEvent read GetOnEditEndDrag write SetOnEditEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnMouseWheelDown;
    property OnMouseWheelUp;
    property OnResize;
    property OnStartDrag: TStartDragEvent read GetOnEditStartDrag write SetOnEditStartDrag;
    property OnUTF8KeyPress;
  end;

procedure Register;

implementation

procedure Register;
begin
  {$IFDEF FPC}
    {$I icons\frmaterialedit_icon.lrs}
  {$ENDIF}
  RegisterComponents('BGRA Controls', [TFRMaterialEdit]);
end;

{ TFRMaterialEditBase }

{ --- Botão de limpeza --- }

function TFRMaterialEditBase.GetShowClearButton: Boolean;
begin
  Result := FShowClearButton;
end;

procedure TFRMaterialEditBase.SetShowClearButton(AValue: Boolean);
begin
  if FShowClearButton = AValue then Exit;
  FShowClearButton := AValue;
  UpdateClearButton;
end;

procedure TFRMaterialEditBase.ClearButtonClick(Sender: TObject);
begin
  FEdit.Text := '';
  FEdit.SetFocus;
  if Assigned(FOnClearButtonClick) then
    FOnClearButtonClick(Self);
end;

procedure TFRMaterialEditBase.InternalEditChange(Sender: TObject);
begin
  UpdateClearButton;
end;

procedure TFRMaterialEditBase.UpdateRightButtonSpacing;
var
  RightSpacing: Integer;
begin
  RightSpacing := 4;
  if Assigned(FClearButton) and FClearButton.Visible then
    Inc(RightSpacing, FClearButton.Width);
  if Assigned(FSearchButton) and FSearchButton.Visible then
  begin
    if Assigned(FClearButton) and FClearButton.Visible then
      Inc(RightSpacing, 2);
    Inc(RightSpacing, FSearchButton.Width);
  end;
  FEdit.BorderSpacing.Right := RightSpacing;
end;

procedure TFRMaterialEditBase.UpdateClearButton;
var
  ShouldShow: Boolean;
begin
  ShouldShow := FShowClearButton and (FEdit.Text <> '') and not FEdit.ReadOnly;
  if ShouldShow = FClearButton.Visible then Exit;

  DisableAlign;
  try
    FClearButton.Visible := ShouldShow;
    UpdateRightButtonSpacing;
  finally
    EnableAlign;
  end;
  Invalidate;
end;

{ --- Botão de pesquisa --- }

function TFRMaterialEditBase.GetShowSearchButton: Boolean;
begin
  Result := FShowSearchButton;
end;

procedure TFRMaterialEditBase.SetShowSearchButton(AValue: Boolean);
begin
  if FShowSearchButton = AValue then Exit;
  FShowSearchButton := AValue;
  DisableAlign;
  try
    FSearchButton.Visible := FShowSearchButton;
    UpdateRightButtonSpacing;
  finally
    EnableAlign;
  end;
  Invalidate;
end;

procedure TFRMaterialEditBase.SearchButtonClick(Sender: TObject);
begin
  if Assigned(FOnSearchButtonClick) then
    FOnSearchButtonClick(Self);
end;

procedure TFRMaterialEditBase.DrawSearchIcon(AColor: TColor);
{ Desenha uma lupa 14×14 px no glyph do botão de pesquisa na cor AColor }
var
  Bmp: TBitmap;
begin
  Bmp := TBitmap.Create;
  try
    Bmp.Width  := 14;
    Bmp.Height := 14;
    { Fundo transparente: TBitBtn usa o pixel inferior-esquerdo como máscara }
    Bmp.Canvas.Brush.Color := clFuchsia;
    Bmp.Canvas.FillRect(Rect(0, 0, 14, 14));
    Bmp.Canvas.Pen.Color  := AColor;
    Bmp.Canvas.Pen.Width  := 2;
    Bmp.Canvas.Brush.Style := bsClear;
    Bmp.Canvas.Ellipse(1, 1, 10, 10);   { círculo da lente }
    Bmp.Canvas.MoveTo(8, 8);
    Bmp.Canvas.LineTo(13, 13);           { cabo da lupa }
    Bmp.Canvas.Pen.Width := 1;
    FSearchButton.Glyph.Assign(Bmp);
  finally
    Bmp.Free;
  end;
end;

{ --- Getters de propriedades do Edit --- }

function TFRMaterialEditBase.GetEditAlignment: TAlignment;
begin
  result := FEdit.Alignment;
end;

function TFRMaterialEditBase.GetEditAutoSize: Boolean;
begin
  result := FEdit.AutoSize;
end;

function TFRMaterialEditBase.GetEditAutoSelect: Boolean;
begin
  result := FEdit.AutoSelect;
end;

function TFRMaterialEditBase.GetEditCharCase: TEditCharCase;
begin
  result := FEdit.CharCase;
end;

function TFRMaterialEditBase.GetEditCursor: TCursor;
begin
  result := FEdit.Cursor;
end;

function TFRMaterialEditBase.GetEditDoubleBuffered: Boolean;
begin
  result := FEdit.DoubleBuffered;
end;

function TFRMaterialEditBase.GetEditEchoMode: TEchoMode;
begin
  result := FEdit.EchoMode;
end;

function TFRMaterialEditBase.GetEditHideSelection: Boolean;
begin
  result := FEdit.HideSelection;
end;

function TFRMaterialEditBase.GetEditHint: TTranslateString;
begin
  result := FEdit.Hint;
end;

function TFRMaterialEditBase.GetEditMaxLength: Integer;
begin
  result := FEdit.MaxLength;
end;

function TFRMaterialEditBase.GetEditNumbersOnly: Boolean;
begin
  result := FEdit.NumbersOnly;
end;

function TFRMaterialEditBase.GetEditPasswordChar: Char;
begin
  result := FEdit.PasswordChar;
end;

function TFRMaterialEditBase.GetEditParentColor: Boolean;
begin
  Result := Self.ParentColor;
end;

function TFRMaterialEditBase.GetEditPopupMenu: TPopupMenu;
begin
  if (csDestroying in ComponentState) then Exit(nil);
  result := FEdit.PopupMenu;
end;

function TFRMaterialEditBase.GetEditReadOnly: Boolean;
begin
  result := FEdit.ReadOnly;
end;

function TFRMaterialEditBase.GetEditShowHint: Boolean;
begin
  result := FEdit.ShowHint;
end;

function TFRMaterialEditBase.GetEditTag: PtrInt;
begin
  result := FEdit.Tag;
end;

function TFRMaterialEditBase.GetEditTabStop: Boolean;
begin
  result := FEdit.TabStop;
end;

function TFRMaterialEditBase.GetEditText: TCaption;
begin
  result := FEdit.Text;
end;

function TFRMaterialEditBase.GetEditTextHint: TCaption;
begin
  result := FEdit.TextHint;
end;

function TFRMaterialEditBase.GetLabelCaption: TCaption;
begin
  result := FLabel.Caption
end;

function TFRMaterialEditBase.GetLabelSpacing: Integer;
begin
  result := FLabel.BorderSpacing.Bottom;
end;

{ --- Getters de eventos do Edit --- }

function TFRMaterialEditBase.GetOnEditChange: TNotifyEvent;
begin
  result := FEdit.OnChange;
end;

function TFRMaterialEditBase.GetOnEditClick: TNotifyEvent;
begin
  result := FEdit.OnClick;
end;

function TFRMaterialEditBase.GetOnEditEditingDone: TNotifyEvent;
begin
  result := FEdit.OnEditingDone;
end;

function TFRMaterialEditBase.GetOnEditEnter: TNotifyEvent;
begin
  result := FEdit.OnEnter;
end;

function TFRMaterialEditBase.GetOnEditExit: TNotifyEvent;
begin
  result := FEdit.OnExit;
end;

function TFRMaterialEditBase.GetOnEditKeyDown: TKeyEvent;
begin
  result := FEdit.OnKeyDown;
end;

function TFRMaterialEditBase.GetOnEditKeyPress: TKeyPressEvent;
begin
  result := FEdit.OnKeyPress;
end;

function TFRMaterialEditBase.GetOnEditKeyUp: TKeyEvent;
begin
  result := FEdit.OnKeyUp;
end;

function TFRMaterialEditBase.GetOnEditMouseDown: TMouseEvent;
begin
  result := FEdit.OnMouseDown;
end;

function TFRMaterialEditBase.GetOnEditMouseEnter: TNotifyEvent;
begin
  result := FEdit.OnMouseEnter;
end;

function TFRMaterialEditBase.GetOnEditMouseLeave: TNotifyEvent;
begin
  result := FEdit.OnMouseLeave;
end;

function TFRMaterialEditBase.GetOnEditMouseMove: TMouseMoveEvent;
begin
  result := FEdit.OnMouseMove;
end;

function TFRMaterialEditBase.GetOnEditMouseUp: TMouseEvent;
begin
  result := FEdit.OnMouseUp;
end;

function TFRMaterialEditBase.GetOnEditMouseWheel: TMouseWheelEvent;
begin
  result := FEdit.OnMouseWheel;
end;

function TFRMaterialEditBase.GetOnEditMouseWheelDown: TMouseWheelUpDownEvent;
begin
  result := FEdit.OnMouseWheelDown;
end;

function TFRMaterialEditBase.GetOnEditMouseWheelUp: TMouseWheelUpDownEvent;
begin
  result := FEdit.OnMouseWheelUp;
end;

function TFRMaterialEditBase.GetOnEditUTF8KeyPress: TUTF8KeyPressEvent;
begin
  result := FEdit.OnUTF8KeyPress;
end;

{ --- Setters de eventos do Edit --- }

procedure TFRMaterialEditBase.SetOnEditChange(AValue: TNotifyEvent);
begin
  FEdit.OnChange := AValue;
end;

procedure TFRMaterialEditBase.SetOnEditClick(AValue: TNotifyEvent);
begin
  FEdit.OnClick := AValue;
end;

procedure TFRMaterialEditBase.SetOnEditEditingDone(AValue: TNotifyEvent);
begin
  FEdit.OnEditingDone := AValue;
end;

procedure TFRMaterialEditBase.SetOnEditEnter(AValue: TNotifyEvent);
begin
  FEdit.OnEnter := AValue;
end;

procedure TFRMaterialEditBase.SetOnEditExit(AValue: TNotifyEvent);
begin
  FEdit.OnExit := AValue;
end;

procedure TFRMaterialEditBase.SetOnEditKeyDown(AValue: TKeyEvent);
begin
  FEdit.OnKeyDown := AValue;
end;

procedure TFRMaterialEditBase.SetOnEditKeyPress(AValue: TKeyPressEvent);
begin
  FEdit.OnKeyPress := AValue;
end;

procedure TFRMaterialEditBase.SetOnEditKeyUp(AValue: TKeyEvent);
begin
  FEdit.OnKeyUp := AValue;
end;

procedure TFRMaterialEditBase.SetOnEditMouseDown(AValue: TMouseEvent);
begin
  FEdit.OnMouseDown := AValue;
end;

procedure TFRMaterialEditBase.SetOnEditMouseEnter(AValue: TNotifyEvent);
begin
  FEdit.OnMouseEnter := AValue;
end;

procedure TFRMaterialEditBase.SetOnEditMouseLeave(AValue: TNotifyEvent);
begin
  FEdit.OnMouseLeave := AValue;
end;

procedure TFRMaterialEditBase.SetOnEditMouseMove(AValue: TMouseMoveEvent);
begin
  FEdit.OnMouseMove := AValue;
end;

procedure TFRMaterialEditBase.SetOnEditMouseUp(AValue: TMouseEvent);
begin
  FEdit.OnMouseUp := AValue;
end;

procedure TFRMaterialEditBase.SetOnEditMouseWheel(AValue: TMouseWheelEvent);
begin
  FEdit.OnMouseWheel := AValue;
end;

procedure TFRMaterialEditBase.SetOnEditMouseWheelDown(AValue: TMouseWheelUpDownEvent);
begin
  FEdit.OnMouseWheelDown := AValue;
end;

procedure TFRMaterialEditBase.SetOnEditMouseWheelUp(AValue: TMouseWheelUpDownEvent);
begin
  FEdit.OnMouseWheelUp := AValue;
end;

procedure TFRMaterialEditBase.SetOnEditUTF8KeyPress(AValue: TUTF8KeyPressEvent);
begin
  FEdit.OnUTF8KeyPress := AValue;
end;

{ --- Setters de propriedades do Edit --- }

function TFRMaterialEditBase.IsNeededAdjustSize: boolean;
begin
  if (Self.Align in [alLeft, alRight, alClient]) then Exit(False);
  if (akTop in Self.Anchors) and (akBottom in Self.Anchors) then Exit(False);
  result := FEdit.AutoSize;
end;

procedure TFRMaterialEditBase.SetAnchors(const AValue: TAnchors);
begin
  if (Self.Anchors = AValue) then Exit;
  inherited SetAnchors(AValue);
  if not (csLoading in ComponentState) then
    Self.DoOnResize;
end;

procedure TFRMaterialEditBase.SetColor(AValue: TColor);
begin
  inherited SetColor(AValue);
  FEdit.Color := AValue;
end;

procedure TFRMaterialEditBase.SetEditAlignment(const AValue: TAlignment);
begin
  FEdit.Alignment := AValue;
end;

procedure TFRMaterialEditBase.SetEditAutoSize(AValue: Boolean);
begin
  if (FEdit.AutoSize = AValue) then Exit;
  FEdit.AutoSize := AValue;
  if not (csLoading in ComponentState) then Self.DoOnResize;
end;

procedure TFRMaterialEditBase.SetEditAutoSelect(AValue: Boolean);
begin
  FEdit.AutoSelect := AValue;
end;

procedure TFRMaterialEditBase.SetEditCharCase(AValue: TEditCharCase);
begin
  FEdit.CharCase := AValue;
end;

procedure TFRMaterialEditBase.SetEditCursor(AValue: TCursor);
begin
  FEdit.Cursor := AValue;
end;

procedure TFRMaterialEditBase.SetEditDoubleBuffered(AValue: Boolean);
begin
  FEdit.DoubleBuffered := AValue;
end;

procedure TFRMaterialEditBase.SetEditEchoMode(AValue: TEchoMode);
begin
  FEdit.EchoMode := AValue;
end;

procedure TFRMaterialEditBase.SetEditHideSelection(AValue: Boolean);
begin
  FEdit.HideSelection := AValue;
end;

procedure TFRMaterialEditBase.SetEditHint(const AValue: TTranslateString);
begin
  FEdit.Hint := AValue;
end;

procedure TFRMaterialEditBase.SetEditMaxLength(AValue: Integer);
begin
  FEdit.MaxLength := AValue;
end;

procedure TFRMaterialEditBase.SetEditNumbersOnly(AValue: Boolean);
begin
  FEdit.NumbersOnly := AValue;
end;

procedure TFRMaterialEditBase.SetEditParentColor(AValue: Boolean);
begin
  FEdit.ParentColor := AValue;
  FLabel.ParentColor := AValue;
end;

procedure TFRMaterialEditBase.SetEditPasswordChar(AValue: Char);
begin
  FEdit.PasswordChar := AValue;
end;

procedure TFRMaterialEditBase.SetEditTabStop(AValue: Boolean);
begin
  FEdit.TabStop := AValue;
end;

procedure TFRMaterialEditBase.SetEditPopupMenu(AValue: TPopupmenu);
begin
  FEdit.PopupMenu := AValue;
end;

procedure TFRMaterialEditBase.SetEditReadOnly(AValue: Boolean);
begin
  FEdit.ReadOnly := AValue;
  UpdateClearButton;
end;

procedure TFRMaterialEditBase.SetEditShowHint(AValue: Boolean);
begin
  FEdit.ShowHint := AValue;
end;

procedure TFRMaterialEditBase.SetEditTag(AValue: PtrInt);
begin
  FEdit.Tag := AValue;
end;

procedure TFRMaterialEditBase.SetEditTextHint(const Avalue: TTranslateString);
begin
  FEdit.TextHint := AValue;
end;

procedure TFRMaterialEditBase.SetEditText(const AValue: TCaption);
begin
  FEdit.Text := AValue;
end;

procedure TFRMaterialEditBase.SetLabelCaption(const AValue: TCaption);
begin
  FLabel.Caption := AValue;
end;

procedure TFRMaterialEditBase.SetLabelSpacing(AValue: Integer);
begin
  if (FLabel.BorderSpacing.Bottom = AValue) then Exit;
  FLabel.BorderSpacing.Bottom := AValue;
  if not (csLoading in ComponentState) then Self.DoOnResize;
end;

procedure TFRMaterialEditBase.SetName(const AValue: TComponentName);
begin
  if (csDesigning in ComponentState) then
  begin
    if (FLabel.Caption = '') or (AnsiSameText(FLabel.Caption, AValue)) then
      FLabel.Caption := 'Label';

    if (FLabel.Name = '') or (AnsiSameText(FLabel.Name, AValue)) then
      FLabel.Name := AValue + 'SubLabel';

    if (FEdit.Text = '') or (AnsiSameText(FEdit.Text, AValue)) then
      FEdit.Text := AValue;

    if (FEdit.Name = '') or (AnsiSameText(FEdit.Name, AValue)) then
      FEdit.Name := AValue + 'SubEdit';
  end;
  inherited SetName(AValue);
end;

procedure TFRMaterialEditBase.DoEnter;
begin
  inherited DoEnter;
  FFocused := True;
  Invalidate;
end;

procedure TFRMaterialEditBase.DoExit;
begin
  FFocused := False;
  Invalidate;
  inherited DoExit;
end;

procedure TFRMaterialEditBase.DoOnResize;
var
  AutoSizedHeight: longint;
  BtnLeft: Integer;
begin
  if IsNeededAdjustSize then
  begin
    FEdit.Align := alBottom;
    AutoSizedHeight :=
      FLabel.Height +
      FLabel.BorderSpacing.Around +
      FLabel.BorderSpacing.Bottom +
      FLabel.BorderSpacing.Top +
      FEdit.Height +
      FEdit.BorderSpacing.Around +
      FEdit.BorderSpacing.Bottom +
      FEdit.BorderSpacing.Top;

    if Self.Height <> AutoSizedHeight then
      Self.Height := AutoSizedHeight;
  end else
  begin
    FEdit.Align := alClient;
  end;

  { Posiciona os botões de ação à direita do campo de edição }
  BtnLeft := FEdit.Left + FEdit.Width + 2;
  if Assigned(FClearButton) and FClearButton.Visible then
  begin
    FClearButton.Height := FEdit.Height - 2;
    FClearButton.Left   := BtnLeft;
    FClearButton.Top    := FEdit.Top + (FEdit.Height - FClearButton.Height) div 2;
    FClearButton.BringToFront;
    Inc(BtnLeft, FClearButton.Width + 2);
  end;
  if Assigned(FSearchButton) and FSearchButton.Visible then
  begin
    FSearchButton.Height := FEdit.Height - 2;
    FSearchButton.Left   := BtnLeft;
    FSearchButton.Top    := FEdit.Top + (FEdit.Height - FSearchButton.Height) div 2;
    FSearchButton.BringToFront;
  end;

  inherited DoOnResize;
end;

procedure TFRMaterialEditBase.Paint;
var
  LeftPos, RightPos, FieldTop, CR: Integer;
  DecoColor: TColor;
begin
  inherited Paint;

  CR := FBorderRadius * 2;
  if FFocused and Self.Enabled then
    DecoColor := AccentColor
  else
    DecoColor := DisabledColor;

  { Extensão horizontal do sublinhado/borda }
  if Assigned(Parent) and (Parent.Color = Color) then
  begin
    LeftPos := FEdit.Left;
    { Estende até cobrir a área dos botões de ação quando visíveis }
    if FSearchButton.Visible then
      RightPos := FSearchButton.Left + FSearchButton.Width
    else if FClearButton.Visible then
      RightPos := FClearButton.Left + FClearButton.Width
    else
      RightPos := FEdit.Left + FEdit.Width;
  end else
  begin
    LeftPos  := 0;
    RightPos := Width;
  end;

  FieldTop := FEdit.Top - 2;
  if FieldTop < 0 then FieldTop := 0;

  { Passo 1: preenchimento do fundo }
  Canvas.Pen.Width   := 1;
  Canvas.Pen.Color   := Color;
  Canvas.Brush.Color := Color;
  case FVariant of
    mvFilled:
      if CR > 0 then
        Canvas.RoundRect(0, 0, Width, Height, CR, CR)
      else
        Canvas.Rectangle(0, 0, Width, Height);
  else
    Canvas.Rectangle(0, 0, Width, Height);
  end;

  { Passo 2: cor do label e decoração do campo }
  Canvas.Pen.Color  := DecoColor;
  FLabel.Font.Color := DecoColor;

  { Atualiza ícone da lupa com a mesma cor do sublinhado }
  if FSearchButton.Visible then
    DrawSearchIcon(DecoColor);

  case FVariant of
    mvStandard, mvFilled:
    begin
      if FFocused and Self.Enabled then
      begin
        Canvas.Line(LeftPos, Height - 2, RightPos, Height - 2);
        Canvas.Line(LeftPos, Height - 1, RightPos, Height - 1);
      end else
        Canvas.Line(LeftPos, Height - 1, RightPos, Height - 1);
    end;
    mvOutlined:
    begin
      Canvas.Brush.Style := bsClear;
      if FFocused and Self.Enabled then
        Canvas.Pen.Width := 2
      else
        Canvas.Pen.Width := 1;
      if CR > 0 then
        Canvas.RoundRect(LeftPos, FieldTop, RightPos, Height - 1, CR, CR)
      else
        Canvas.Rectangle(LeftPos, FieldTop, RightPos, Height - 1);
      Canvas.Pen.Width   := 1;
      Canvas.Brush.Style := bsSolid;
    end;
  end;
end;

constructor TFRMaterialEditBase.Create(AOwner: TComponent);
begin
  FEdit := T.Create(Self);
  FLabel := TBoundLabel.Create(Self);
  inherited Create(AOwner);

  Self.AccentColor := clHighlight;
  Self.BorderStyle := bsNone;
  Self.Color := clWindow;
  Self.DisabledColor := $00B8AFA8;
  Self.ParentColor := False;

  FLabel.Align := alTop;
  FLabel.AutoSize := True;
  FLabel.BorderSpacing.Around := 0;
  FLabel.BorderSpacing.Bottom := 4;
  FLabel.BorderSpacing.Left := 4;
  FLabel.BorderSpacing.Right := 4;
  FLabel.BorderSpacing.Top := 4;
  FLabel.Font.Color := $00B8AFA8;
  FLabel.Font.Style := [fsBold];
  FLabel.Parent := Self;
  FLabel.ParentFont := False;
  FLabel.ParentBiDiMode := True;
  FLabel.SetSubComponent(True);

  FEdit.Align := alBottom;
  FEdit.AutoSelect := True;
  FEdit.AutoSize := True;
  FEdit.BorderSpacing.Around := 0;
  FEdit.BorderSpacing.Bottom := 4;
  FEdit.BorderSpacing.Left := 4;
  FEdit.BorderSpacing.Right := 4;
  FEdit.BorderSpacing.Top := 0;
  FEdit.BorderStyle := bsNone;
  FEdit.Color := Color;
  FEdit.Font.Color := clBlack;
  FEdit.Parent := Self;
  FEdit.ParentFont := True;
  FEdit.ParentBiDiMode := True;
  FEdit.TabStop := True;
  FEdit.SetSubComponent(True);

  { Monitora mudanças de texto para mostrar/ocultar o botão de limpeza.
    AddHandlerOnChange é usado para não sobrescrever o OnChange do usuário. }
  FEdit.AddHandlerOnChange(@InternalEditChange);

  { Configura o botão de limpeza }
  FClearButton := TButton.Create(Self);
  FClearButton.Caption := '×';      { × — sinal de multiplicação (U+00D7) }
  FClearButton.Width := 22;
  FClearButton.Height := 22;
  FClearButton.TabStop := False;     { não participa da ordem de tabulação }
  FClearButton.Visible := False;
  FClearButton.Parent := Self;
  FClearButton.OnClick := @ClearButtonClick;
  FClearButton.SetSubComponent(True);

  { Configura o botão de pesquisa }
  FSearchButton := TBitBtn.Create(Self);
  FSearchButton.Caption  := '';
  FSearchButton.Width    := 22;
  FSearchButton.Height   := 22;
  FSearchButton.TabStop  := False;
  FSearchButton.Visible  := False;
  FSearchButton.Parent   := Self;
  FSearchButton.OnClick  := @SearchButtonClick;
  FSearchButton.SetSubComponent(True);
  DrawSearchIcon(DisabledColor);

  FShowClearButton  := False;
  FShowSearchButton := False;
  FVariant          := mvStandard;
  FBorderRadius     := 0;
end;

{ TFRMaterialEdit }

function TFRMaterialEdit.GetEditDragCursor: TCursor;
begin
  result := FEdit.DragCursor;
end;

function TFRMaterialEdit.GetEditDragMode: TDragMode;
begin
  result := FEdit.DragMode;
end;

function TFRMaterialEdit.GetOnEditContextPopup: TContextPopupEvent;
begin
  result := FEdit.OnContextPopup;
end;

function TFRMaterialEdit.GetOnEditDblClick: TNotifyEvent;
begin
  result := FEdit.OnDblClick;
end;

function TFRMaterialEdit.GetOnEditDragDrop: TDragDropEvent;
begin
  result := FEdit.OnDragDrop;
end;

function TFRMaterialEdit.GetOnEditDragOver: TDragOverEvent;
begin
  result := FEdit.OnDragOver;
end;

function TFRMaterialEdit.GetOnEditEndDrag: TEndDragEvent;
begin
  result := FEdit.OnEndDrag;
end;

function TFRMaterialEdit.GetOnEditStartDrag: TStartDragEvent;
begin
  result := FEdit.OnStartDrag;
end;

procedure TFRMaterialEdit.SetEditDragCursor(AValue: TCursor);
begin
  FEdit.DragCursor := AValue;
end;

procedure TFRMaterialEdit.SetEditDragMode(AValue: TDragMode);
begin
  FEdit.DragMode := AValue;
end;

procedure TFRMaterialEdit.SetOnEditContextPopup(AValue: TContextPopupEvent);
begin
  FEdit.OnContextPopup := AValue;
end;

procedure TFRMaterialEdit.SetOnEditDblClick(AValue: TNotifyEvent);
begin
  FEdit.OnDblClick := AValue;
end;

procedure TFRMaterialEdit.SetOnEditDragDrop(AValue: TDragDropEvent);
begin
  FEdit.OnDragDrop := AValue;
end;

procedure TFRMaterialEdit.SetOnEditDragOver(AValue: TDragOverEvent);
begin
  FEdit.OnDragOver := AValue;
end;

procedure TFRMaterialEdit.SetOnEditEndDrag(AValue: TEndDragEvent);
begin
  FEdit.OnEndDrag := AValue;
end;

procedure TFRMaterialEdit.SetOnEditStartDrag(AValue: TStartDragEvent);
begin
  FEdit.OnStartDrag := AValue;
end;

end.
