unit FRMaterial3Label;

{$mode delphi}{$H+}

{ TFRMaterialLabel — theme-aware label with MD3 color tokens.

  Problem this solves
  ───────────────────
  A raw TLabel takes MD3Colors.* at assignment time and never updates
  when the theme changes at runtime (dark mode toggle, palette switch,
  etc). This breaks contrast in dark mode since every text label keeps
  the light-mode color it was assigned at construction.

  TFRMaterialLabel implements IFRMaterialComponent and registers with
  the theme manager. When the theme changes, it re-reads MD3Colors
  via the ColorToken property and updates Font.Color accordingly.

  Usage
  ─────
  At design time: drop TFRMaterialLabel on the form and set
  ColorToken to the semantic role you want (ctOnSurface for body text,
  ctOnSurfaceVariant for hints, ctPrimary for overlines, etc).

  In code:
      L := TFRMaterialLabel.Create(Self);
      L.Parent := SomePanel;
      L.Caption := 'Section title';
      L.ColorToken := ctPrimary;

  Tokens follow the MD3 spec. Add more here if a new role is needed.

  License: LGPL v3 with LCL-style linking exception (see LICENSE). }

interface

uses
  Classes, SysUtils, Controls, Graphics, StdCtrls,
  FRMaterial3Base, FRMaterialTheme;

type
  { Semantic color role for a TFRMaterialLabel. The actual TColor is
    resolved at ApplyTheme time from MD3Colors, so the label follows
    theme changes automatically. }
  TFRMDColorToken = (
    ctOnSurface,
    ctOnSurfaceVariant,
    ctOnSurfaceDisabled,
    ctPrimary,
    ctOnPrimary,
    ctOnPrimaryContainer,
    ctSecondary,
    ctOnSecondary,
    ctOnSecondaryContainer,
    ctTertiary,
    ctOnTertiary,
    ctOnTertiaryContainer,
    ctError,
    ctOnError,
    ctOnErrorContainer,
    ctOutline,
    ctOutlineVariant,
    ctInverseSurface,
    ctInverseOnSurface,
    ctInversePrimary
  );

  { TFRMaterialLabel }

  TFRMaterialLabel = class(TCustomLabel, IFRMaterialComponent)
  private
    FColorToken: TFRMDColorToken;
    FTokenActive: Boolean;
    procedure SetColorToken(AValue: TFRMDColorToken);
    function TokenToColor(AToken: TFRMDColorToken): TColor;
  protected
    procedure Loaded; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure BeforeDestruction; override;
    procedure ApplyTheme(const AThemeManager: TObject); virtual;
  published
    { Semantic role token — when set, Font.Color is automatically resolved
      from MD3Colors and refreshed on every theme change. Set to
      ctOnSurface (default) for body text, ctOnSurfaceVariant for hints
      and captions, ctPrimary for overlines and accents. }
    property ColorToken: TFRMDColorToken read FColorToken write SetColorToken
      default ctOnSurface;

    { Inherited TLabel properties }
    property Align;
    property Alignment;
    property Anchors;
    property AutoSize;
    property BiDiMode;
    property BorderSpacing;
    property Caption;
    property Color;
    property Constraints;
    property DragCursor;
    property DragMode;
    property Enabled;
    property FocusControl;
    property Font;
    property Layout;
    property ParentBiDiMode;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowAccelChar;
    property ShowHint;
    property Transparent;
    property Visible;
    property WordWrap;
    property OnChangeBounds;
    property OnClick;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnMouseWheelDown;
    property OnMouseWheelUp;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
  end;

procedure Register;

implementation

{ TFRMaterialLabel }

constructor TFRMaterialLabel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FColorToken := ctOnSurface;
  FTokenActive := True;
  { Default to transparent so the label blends into its parent's
    background (normal TLabel behavior in MD3 forms). }
  Transparent := True;
  { Apply initial color based on the current theme. Guarded by
    FTokenActive so we can restore theme responsiveness later. }
  Font.Color := TokenToColor(FColorToken);
  { Register as theme listener — will be unregistered in BeforeDestruction. }
  FRMDRegisterComponent(Self);
end;

destructor TFRMaterialLabel.Destroy;
begin
  inherited Destroy;
end;

procedure TFRMaterialLabel.BeforeDestruction;
begin
  FRMDUnregisterComponent(Self);
  inherited BeforeDestruction;
end;

procedure TFRMaterialLabel.Loaded;
begin
  inherited Loaded;
  { After LFM streaming: re-resolve the color via the current theme,
    since the palette may have been switched by CarregarTemaSistema
    (or equivalent) before our form loaded. }
  if Assigned(FRMaterialDefaultThemeManager) then
    ApplyTheme(FRMaterialDefaultThemeManager);
end;

procedure TFRMaterialLabel.SetColorToken(AValue: TFRMDColorToken);
begin
  if FColorToken = AValue then Exit;
  FColorToken := AValue;
  FTokenActive := True;
  Font.Color := TokenToColor(FColorToken);
  FRMDSafeInvalidate(Self);
end;

function TFRMaterialLabel.TokenToColor(AToken: TFRMDColorToken): TColor;
begin
  case AToken of
    ctOnSurface:            Result := MD3Colors.OnSurface;
    ctOnSurfaceVariant:     Result := MD3Colors.OnSurfaceVariant;
    ctOnSurfaceDisabled:    Result := MD3Blend(MD3Colors.Surface,
                                         MD3Colors.OnSurface, 97);
    ctPrimary:              Result := MD3Colors.Primary;
    ctOnPrimary:            Result := MD3Colors.OnPrimary;
    ctOnPrimaryContainer:   Result := MD3Colors.OnPrimaryContainer;
    ctSecondary:            Result := MD3Colors.Secondary;
    ctOnSecondary:          Result := MD3Colors.OnSecondary;
    ctOnSecondaryContainer: Result := MD3Colors.OnSecondaryContainer;
    ctTertiary:             Result := MD3Colors.Tertiary;
    ctOnTertiary:           Result := MD3Colors.OnTertiary;
    ctOnTertiaryContainer:  Result := MD3Colors.OnTertiaryContainer;
    ctError:                Result := MD3Colors.Error;
    ctOnError:              Result := MD3Colors.OnError;
    ctOnErrorContainer:     Result := MD3Colors.OnErrorContainer;
    ctOutline:              Result := MD3Colors.Outline;
    ctOutlineVariant:       Result := MD3Colors.OutlineVariant;
    ctInverseSurface:       Result := MD3Colors.InverseSurface;
    ctInverseOnSurface:     Result := MD3Colors.InverseOnSurface;
    ctInversePrimary:       Result := MD3Colors.InversePrimary;
  else
    Result := MD3Colors.OnSurface;
  end;
end;

procedure TFRMaterialLabel.ApplyTheme(const AThemeManager: TObject);
begin
  if not Assigned(AThemeManager) then Exit;
  if FRMDIsDestroying(Self) then Exit;
  if not FTokenActive then Exit;

  Font.Color := TokenToColor(FColorToken);
  FRMDSafeInvalidate(Self);
end;

{ ── Registration ── }

procedure Register;
begin
  RegisterComponents('Material Design 3', [TFRMaterialLabel]);
end;

end.
