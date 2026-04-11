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
  Classes, SysUtils, Controls, Forms, Graphics, TypInfo,
  FRMaterial3Base, FRMaterialTheme, FRMaterialIcons;

type
  TFRMaterialThemeManager = class(TComponent, IFRMaterialThemeManager)
  private
    FPalette  : TFRMDPalette;
    FDarkMode : Boolean;
    FSeedColor: TColor;
    FUseSeed  : Boolean;
    FDensity: TFRMDDensity;
    FVariant: TFRMaterialVariant;
    FListeners: TFPList;
    FApplying: Boolean;
    procedure SetPalette(AValue: TFRMDPalette);
    procedure SetDarkMode(AValue: Boolean);
    procedure SetSeedColor(AValue: TColor);
    procedure SetUseSeed(AValue: Boolean);
    procedure SetDensity(AValue: TFRMDDensity);
    procedure SetVariant(AValue: TFRMaterialVariant);
    procedure ApplyTheme;
    function GetDensity: TFRMDDensity;
    function GetVariant: TFRMaterialVariant;
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
    { Densidade visual global: propaga para todos os componentes MD3 }
    property Density: TFRMDDensity read FDensity write SetDensity default ddNormal;
    { Variante visual global dos campos: Standard, Filled ou Outlined }
    property Variant: TFRMaterialVariant read FVariant write SetVariant default mvStandard;
  end;

procedure Register;

implementation

{ ── TFRMaterialThemeManager ── }

constructor TFRMaterialThemeManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FListeners := TFPList.Create;
  if FRMaterialDefaultThemeManager = nil then
    FRMaterialDefaultThemeManager := Self;
    
  FPalette   := mpBaseline;
  FDarkMode  := False;
  FSeedColor := $006750A4; { Material Baseline purple }
  FUseSeed   := False;
  FDensity   := ddNormal;
  FVariant   := mvStandard;
  FApplying  := False;
end;

destructor TFRMaterialThemeManager.Destroy;
begin
  if FRMaterialDefaultThemeManager = Self then
    FRMaterialDefaultThemeManager := nil;
  FreeAndNil(FListeners);
  inherited Destroy;
end;

procedure TFRMaterialThemeManager.RegisterComponent(AComponent: IFRMaterialComponent);
begin
  if not Assigned(FListeners) then Exit;
  if FListeners.IndexOf(Pointer(AComponent)) >= 0 then Exit;

  FListeners.Add(Pointer(AComponent));

  { NAO empurrar ApplyTheme aqui. Este metodo eh chamado do construtor
    base (TFRMaterial3Control.Create), momento em que o construtor do
    descendente ainda nao rodou — FDisplayEdit, FLabel etc sao nil.
    Chamar ApplyTheme virtualmente nesse ponto crasha com AV em campo
    nil do derivado. A sincronizacao inicial do tema eh feita via:

      1. LFM-loaded components: TFRMaterial3Control.Loaded override
         chama ApplyTheme DEPOIS que o streaming completa e todos os
         sub-componentes estao construidos.

      2. Code-created components: o chamador aplica tema explicitamente
         quando necessario (ex: uFmMain.ApplyMD3Colors apos criar UI
         dinamica).

    A partir do proximo SetDarkMode/SetDensity/SetVariant, ApplyTheme
    propaga normalmente para todos os listeners. }
end;

procedure TFRMaterialThemeManager.UnregisterComponent(AComponent: IFRMaterialComponent);
begin
  if Assigned(FListeners) then
    FListeners.Remove(Pointer(AComponent));
end;

procedure TFRMaterialThemeManager.ApplyTheme;
var
  i: Integer;
  Comp: IFRMaterialComponent;
begin
  { Reentrancy guard — se um listener dentro do seu ApplyTheme mexer em
    Palette/DarkMode/Density/Variant, os setters tentam chamar ApplyTheme
    de novo. Sem este guard entramos em loop infinito e (pior) iteramos
    FListeners com contagem mudando a cada passo. }
  if FApplying then Exit;
  FApplying := True;
  try
    { Gera o novo esquema de cores e popula a global MD3Colors }
    if FUseSeed then
      MD3GenerateScheme(FSeedColor, FDarkMode)
    else
      MD3LoadPalette(FPalette, FDarkMode);

    { Limpa o cache de ícones para que sejam re-renderizados com as novas cores }
    FRClearIconCache;

    { Propaga invalidação para todos os observers. Iteramos de tras para
      frente para resistir a remocoes (componente desregistrando dentro
      do proprio ApplyTheme). }
    if Assigned(FListeners) then
      for i := FListeners.Count - 1 downto 0 do
      begin
        if i >= FListeners.Count then Continue;
        { Nil pointer check ANTES do cast — protege contra slots ja
          nilled (defensivo, mesmo com unregister correto). }
        if FListeners[i] = nil then Continue;
        Comp := IFRMaterialComponent(FListeners[i]);
        if Assigned(Comp) then
        try
          Comp.ApplyTheme(Self);
        except
          { Um listener que crashar nao pode derrubar todos os outros. }
        end;
      end;
  finally
    FApplying := False;
  end;
end;

procedure TFRMaterialThemeManager.Apply;
begin
  ApplyTheme;
end;

function TFRMaterialThemeManager.GetDensity: TFRMDDensity;
begin
  Result := FDensity;
end;

function TFRMaterialThemeManager.GetVariant: TFRMaterialVariant;
begin
  Result := FVariant;
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

procedure TFRMaterialThemeManager.SetDensity(AValue: TFRMDDensity);
begin
  if FDensity = AValue then Exit;
  FDensity := AValue;
  if not (csLoading in ComponentState) then
    ApplyTheme;
end;


procedure TFRMaterialThemeManager.SetVariant(AValue: TFRMaterialVariant);
begin
  if FVariant = AValue then Exit;
  FVariant := AValue;
  if not (csLoading in ComponentState) then
    ApplyTheme;
end;


procedure Register;
begin
  RegisterComponents('Material Design 3', [TFRMaterialThemeManager]);
end;

end.
