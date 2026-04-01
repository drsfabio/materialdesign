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
    FListeners: TInterfaceList;
    procedure SetPalette(AValue: TFRMDPalette);
    procedure SetDarkMode(AValue: Boolean);
    procedure SetSeedColor(AValue: TColor);
    procedure SetUseSeed(AValue: Boolean);
    procedure ApplyTheme;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    procedure RegisterComponent(AComponent: IFRMaterialComponent);
    procedure UnregisterComponent(AComponent: IFRMaterialComponent);

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
  FListeners := TInterfaceList.Create;
  if FRMaterialDefaultThemeManager = nil then
    FRMaterialDefaultThemeManager := Self;
    
  FPalette   := mpBaseline;
  FDarkMode  := False;
  FSeedColor := $006750A4; { Material Baseline purple }
  FUseSeed   := False;
end;

destructor TFRMaterialThemeManager.Destroy;
begin
  if FRMaterialDefaultThemeManager = Self then
    FRMaterialDefaultThemeManager := nil;
  FListeners.Free;
  inherited Destroy;
end;

procedure TFRMaterialThemeManager.RegisterComponent(AComponent: IFRMaterialComponent);
begin
  if Assigned(FListeners) and (FListeners.IndexOf(AComponent) < 0) then
    FListeners.Add(AComponent);
end;

procedure TFRMaterialThemeManager.UnregisterComponent(AComponent: IFRMaterialComponent);
begin
  if Assigned(FListeners) then
    FListeners.Remove(AComponent);
end;

procedure TFRMaterialThemeManager.ApplyTheme;
var
  i: Integer;
  Comp: IFRMaterialComponent;
begin
  { Gera o novo esquema de cores e popula a global MD3Colors }
  if FUseSeed then
    MD3GenerateScheme(FSeedColor, FDarkMode)
  else
    MD3LoadPalette(FPalette, FDarkMode);

  { Propaga invalidação para todos os observers }
  if Assigned(FListeners) then
    for i := 0 to FListeners.Count - 1 do
    begin
      Comp := IFRMaterialComponent(FListeners[i]);
      if Assigned(Comp) then
        Comp.ApplyTheme(Self);
    end;
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
