unit FRMaterialTheme;

{$mode objfpc}{$H+}

{ Utilitários de tema compartilhados pelos componentes Material Design.

  Exporta:
    TFRMaterialVariant — enum para os três estilos visuais de campo
    MCLuminance        — luminância relativa de uma cor (WCAG 2.1)
    MCContrastRatio    — razão de contraste entre duas cores (WCAG 2.1)
    MCContrastText     — retorna clBlack ou clWhite para máximo contraste

  Licença: LGPL v3 — mesma do bgracontrols
}

interface

uses
  Graphics, Math;

type
  { Variante visual do campo Material Design.

    mvStandard : apenas sublinhado na base (estilo MD2 — padrão histórico)
    mvFilled   : campo preenchido com cantos arredondados + sublinhado na base
    mvOutlined : moldura retangular/arredondada sem sublinhado (estilo MD3)
  }
  TFRMaterialVariant = (
    mvStandard,
    mvFilled,
    mvOutlined
  );

  { Density scale MD3. Cada nível reduz alturas em 4px.
    Equiv: 0, -1, -2, -3 na spec MD3. }
  TFRMDDensity = (
    ddNormal,     { 0dp  — padrão MD3          }
    ddCompact,    { -4px — formulários médios  }
    ddDense,      { -8px — tabelas / grids     }
    ddUltraDense  { -12px — espaço mínimo      }
  );

  { Interface a ser implementada por todo componente que desejar
    ouvir mudanças globais de tema/paleta. }
  IFRMaterialComponent = interface
    ['{6BC17C2F-4A93-4B0F-8761-DCED7B94B5CB}']
    procedure ApplyTheme(const AThemeManager: TObject);
  end;

var
  FRMaterialDefaultThemeManager: TObject = nil;

{ Retorna a luminância relativa de AColor segundo o modelo WCAG 2.1 (0..1).
  Use para calcular contraste entre cores de texto e fundo. }
function MCLuminance(AColor: TColor): Single;

{ Retorna a razão de contraste WCAG 2.1 entre AFg (frente) e ABg (fundo).
  Valores: 1 (sem contraste) … 21 (preto sobre branco).
  AA large requer >= 3.0; AA normal >= 4.5; AAA >= 7.0. }
function MCContrastRatio(AFg, ABg: TColor): Single;

{ Retorna clBlack ou clWhite — a cor que garante maior contraste sobre ABg.
  Útil para escolher automaticamente a cor de legenda/ícone sobre qualquer fundo.

  Exemplo:
    FLabel.Font.Color := MCContrastText(Self.Color);
}
function MCContrastText(ABg: TColor): TColor;

{ Retorna o delta em pixels para a escala de densidade.
  Normal=0, Compact=-4, Dense=-8, UltraDense=-12. }
function MD3DensityDelta(ADensity: TFRMDDensity): Integer;

implementation

{ Lineariza um canal de cor de 0-255 para espaço linear (sRGB → linear RGB) }
function MCLinearize(AChannel: Byte): Single;
var
  S: Single;
begin
  S := AChannel / 255.0;
  if S <= 0.04045 then
    Result := S / 12.92
  else
    Result := Power((S + 0.055) / 1.055, 2.4);
end;

function MCLuminance(AColor: TColor): Single;
var
  C: TColor;
begin
  C := ColorToRGB(AColor);
  Result :=
    0.2126 * MCLinearize(Red(C)) +
    0.7152 * MCLinearize(Green(C)) +
    0.0722 * MCLinearize(Blue(C));
end;

function MCContrastRatio(AFg, ABg: TColor): Single;
var
  L1, L2, Tmp: Single;
begin
  L1 := MCLuminance(AFg);
  L2 := MCLuminance(ABg);
  if L1 < L2 then
  begin
    Tmp := L1;
    L1  := L2;
    L2  := Tmp;
  end;
  Result := (L1 + 0.05) / (L2 + 0.05);
end;

function MCContrastText(ABg: TColor): TColor;
begin
  if MCContrastRatio(clWhite, ABg) >= MCContrastRatio(clBlack, ABg) then
    Result := clWhite
  else
    Result := clBlack;
end;

function MD3DensityDelta(ADensity: TFRMDDensity): Integer;
const
  Deltas: array[TFRMDDensity] of Integer = (0, -4, -8, -12);
begin
  Result := Deltas[ADensity];
end;

end.
