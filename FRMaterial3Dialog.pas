unit FRMaterial3Dialog;

{$mode objfpc}{$H+}

{ Material Design 3 — Dialog.

  TFRMaterialDialog — Modal dialog component with MD3 styling.
  Non-visual component; call Execute to show.

  License: LGPL v3
}

interface

uses
  Classes, SysUtils, Controls, Graphics, Forms, StdCtrls, ExtCtrls, Buttons,
  {$IFDEF FPC} LResources, {$ENDIF}
  BGRABitmap, BGRABitmapTypes, FRMaterial3Base;

type
  TFRMDDialogButton = (dbNone, dbOK, dbCancel, dbYes, dbNo, dbClose);
  TFRMDDialogButtons = set of TFRMDDialogButton;
  TFRMDDialogResult = (drNone, drOK, drCancel, drYes, drNo, drClose);

  { ── TFRMaterialDialog ── }

  TFRMaterialDialog = class(TComponent)
  private
    FTitle: string;
    FContent: string;
    FButtons: TFRMDDialogButtons;
    FShowIcon: Boolean;
    procedure SetTitle(const AValue: string);
    procedure SetContent(const AValue: string);
  public
    constructor Create(AOwner: TComponent); override;
    function Execute: TFRMDDialogResult;
  published
    property Title: string read FTitle write SetTitle;
    property Content: string read FContent write SetContent;
    property Buttons: TFRMDDialogButtons read FButtons write FButtons default [dbOK, dbCancel];
    property ShowIcon: Boolean read FShowIcon write FShowIcon default False;
  end;

procedure Register;

implementation

type
  { Internal form for the dialog }
  TFRDialogForm = class(TForm)
  private
    FResult: TFRMDDialogResult;
    FPanel: TPanel;
    procedure BtnClick(Sender: TObject);
  public
    constructor CreateDialog(ATitle, AContent: string; AButtons: TFRMDDialogButtons);
  end;

constructor TFRDialogForm.CreateDialog(ATitle, AContent: string; AButtons: TFRMDDialogButtons);
var
  lblTitle, lblContent: TLabel;
  btn: TButton;
  btnX: Integer;

  procedure AddBtn(ABtnType: TFRMDDialogButton; const ACaption: string);
  begin
    btn := TButton.Create(Self);
    btn.Parent := FPanel;
    btn.Caption := ACaption;
    btn.Tag := Ord(ABtnType);
    btn.OnClick := @BtnClick;
    btn.Width := 80;
    btn.Height := 36;
    btn.Left := btnX;
    btn.Top := FPanel.Height - 52;
    btn.Font.Color := MD3Colors.Primary;
    btn.Font.Style := [fsBold];
    btnX := btnX + 88;
  end;

begin
  inherited CreateNew(nil);
  FResult := drNone;
  BorderStyle := bsNone;
  Position := poScreenCenter;
  Color := MD3Colors.SurfaceContainerHigh;
  Width := 360;
  Height := 220;
  FormStyle := fsStayOnTop;

  FPanel := TPanel.Create(Self);
  FPanel.Parent := Self;
  FPanel.Align := alClient;
  FPanel.BevelOuter := bvNone;
  FPanel.Color := MD3Colors.SurfaceContainerHigh;

  lblTitle := TLabel.Create(Self);
  lblTitle.Parent := FPanel;
  lblTitle.Left := 24;
  lblTitle.Top := 24;
  lblTitle.Width := Width - 48;
  lblTitle.Font.Size := 14;
  lblTitle.Font.Color := MD3Colors.OnSurface;
  lblTitle.Caption := ATitle;

  lblContent := TLabel.Create(Self);
  lblContent.Parent := FPanel;
  lblContent.Left := 24;
  lblContent.Top := 64;
  lblContent.Width := Width - 48;
  lblContent.WordWrap := True;
  lblContent.Font.Size := 10;
  lblContent.Font.Color := MD3Colors.OnSurfaceVariant;
  lblContent.Caption := AContent;

  btnX := Width - 24;
  { Add buttons right-to-left — confirm actions go rightmost per MD3 spec }
  if dbOK in AButtons then begin btnX := btnX - 88; AddBtn(dbOK, 'OK'); end;
  if dbYes in AButtons then begin btnX := btnX - 88; AddBtn(dbYes, 'Sim'); end;
  if dbClose in AButtons then begin btnX := btnX - 88; AddBtn(dbClose, 'Fechar'); end;
  if dbNo in AButtons then begin btnX := btnX - 88; AddBtn(dbNo, 'Não'); end;
  if dbCancel in AButtons then begin btnX := btnX - 88; AddBtn(dbCancel, 'Cancelar'); end;
end;

procedure TFRDialogForm.BtnClick(Sender: TObject);
begin
  case TFRMDDialogButton(TButton(Sender).Tag) of
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
  FTitle := 'Título';
  FContent := 'Conteúdo da mensagem.';
  FButtons := [dbOK, dbCancel];
  FShowIcon := False;
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
  dlg := TFRDialogForm.CreateDialog(FTitle, FContent, FButtons);
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
  RegisterComponents('BGRA Controls', [TFRMaterialDialog]);
end;

end.
