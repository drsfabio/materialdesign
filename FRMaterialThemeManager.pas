unit FRMaterialThemeManager;

{$mode objfpc}{$H+}

{ TFRMaterialThemeManager — Componente não-visual para gerenciamento de tema MD3.

  Permite trocar entre modo claro/escuro, selecionar uma paleta pré-definida
  ou gerar um esquema de cores a partir de uma cor-semente (seed color),
  em tempo de execução sem reinicialização dos formulários.

  Uso típico:
    ThemeManager1.DarkMode := True;   // troca para dark
    ThemeManager1.Palette  := mpBlue; // muda para paleta azul
    ThemeManager1.SeedColor := $0033CC; // gera esquema a partir da cor

  Licença: LGPL v3 — mesma do bgracontrols
}

interface

uses
  Classes, SysUtils, Controls, Forms, Graphics,
  FRMaterial3Base, FRMaterialTheme;

type
  TFRMaterialThemeManager = class(TComponent)
  private
    FPalette  : TFRMDPalette;
    FDarkMode : Boolean;
    FSeedColor: TColor;
    FUseSeed  : Boolean;
    procedure SetPalette(AValue: TFRMDPalette);
    procedure SetDarkMode(AValue: Boolean);
    procedure SetSeedColor(AValue: TColor);
    procedure SetUseSeed(AValue: Boolean);
    procedure ApplyTheme;
    procedure InvalidateAllControls(AControl: TWinControl);
  public
    constructor Create(AOwner: TComponent); override;
    { Aplica o tema atual explicitamente (útil após mudanças em cascata) }
    procedure Apply;
  published
    { Paleta nomeada — usada quando UseSeed = False }
    property Palette: TFRMDPalette read FPalette write SetPalette default mpBaseline;
    { Quando True, usa dark scheme; False = light scheme }
    property DarkMode: Boolean read FDarkMode write SetDarkMode default False;
    { Cor-semente para geração algorítmica do esquema de cores }
    property SeedColor: TColor read FSeedColor write SetSeedColor default $006750A4;
    { Quando True, ignora Palette e gera o esquema a partir de SeedColor }
    property UseSeed: Boolean read FUseSeed write SetUseSeed default False;
  end;

procedure Register;

implementation

{ ── TFRMaterialThemeManager ── }

constructor TFRMaterialThemeManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPalette   := mpBaseline;
  FDarkMode  := False;
  FSeedColor := $006750A4; { Material Baseline purple }
  FUseSeed   := False;
end;

procedure TFRMaterialThemeManager.InvalidateAllControls(AControl: TWinControl);
var
  i: Integer;
begin
  if AControl = nil then Exit;
  AControl.Invalidate;
  for i := 0 to AControl.ControlCount - 1 do
    if AControl.Controls[i] is TWinControl then
      InvalidateAllControls(TWinControl(AControl.Controls[i]))
    else
      AControl.Controls[i].Invalidate;
end;

procedure TFRMaterialThemeManager.ApplyTheme;
var
  i: Integer;
begin
  { Gera o novo esquema de cores }
  if FUseSeed then
    MD3GenerateScheme(FSeedColor, FDarkMode)
  else
    MD3LoadPalette(FPalette, FDarkMode);

  { Propaga invalidação para todos os forms abertos }
  if Application <> nil then
    for i := 0 to Screen.FormCount - 1 do
      if Screen.Forms[i].Visible then
        InvalidateAllControls(Screen.Forms[i]);
end;

procedure TFRMaterialThemeManager.Apply;
begin
  ApplyTheme;
end;

procedure TFRMaterialThemeManager.SetPalette(AValue: TFRMDPalette);
begin
  if FPalette = AValue then Exit;
  FPalette := AValue;
  FUseSeed := False;
  if not (csLoading in ComponentState) then
    ApplyTheme;
end;

procedure TFRMaterialThemeManager.SetDarkMode(AValue: Boolean);
begin
  if FDarkMode = AValue then Exit;
  FDarkMode := AValue;
  if not (csLoading in ComponentState) then
    ApplyTheme;
end;

procedure TFRMaterialThemeManager.SetSeedColor(AValue: TColor);
begin
  if FSeedColor = AValue then Exit;
  FSeedColor := AValue;
  FUseSeed := True;
  if not (csLoading in ComponentState) then
    ApplyTheme;
end;

procedure TFRMaterialThemeManager.SetUseSeed(AValue: Boolean);
begin
  if FUseSeed = AValue then Exit;
  FUseSeed := AValue;
  if not (csLoading in ComponentState) then
    ApplyTheme;
end;

procedure Register;
begin
  RegisterComponents('Material Design 3', [TFRMaterialThemeManager]);
end;

end.
