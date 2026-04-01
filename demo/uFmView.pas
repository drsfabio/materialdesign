unit uFmView;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, FRMaterialEdit, FRMaterialDateEdit,
  FRMaterialComboEdit, FRMaterialCheckComboEdit, FRMaterialMaskEdit, FRMaterialCurrencyEdit,
  FRMaterialSpinEdit, FRMaterialSearchEdit, FRMaterial3Button, FRMaterial3Chip, FRMaterial3Progress;

type

  { TFmView }

  TFmView = class(TForm)
    FRMaterialButton1: TFRMaterialButton;
    FRMaterialCheckComboEdit1: TFRMaterialCheckComboEdit;
    FRMaterialChip1: TFRMaterialChip;
    FRMaterialComboEdit1: TFRMaterialComboEdit;
    FRMaterialCurrencyEdit1: TFRMaterialCurrencyEdit;
    FRMaterialDateEdit1: TFRMaterialDateEdit;
    FRMaterialEdit1: TFRMaterialEdit;
    FRMaterialEdit2: TFRMaterialEdit;
    FRMaterialLoadingIndicator1: TFRMaterialLoadingIndicator;
    FRMaterialMaskEdit1: TFRMaterialMaskEdit;
    FRMaterialSearchEdit1: TFRMaterialSearchEdit;
    FRMaterialSpinEdit1: TFRMaterialSpinEdit;
    FRMaterialSplitButton1: TFRMaterialSplitButton;
  private

  public

  end;

var
  FFmView: TFmView;

implementation

{$R *.lfm}

end.

