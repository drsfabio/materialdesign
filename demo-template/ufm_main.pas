unit ufm_main;

{$mode objfpc}{$H+}

{ Template: Material Design 3 Application with TFRMaterialForm.
  - Borderless window with DWM rounded corners + shadow
  - Built-in TitleBar with minimize/maximize/close
  - Custom action buttons in the titlebar
  - MD3 theme support (light/dark, palettes, density)

  Usage:
    1. Open app_template.lpi in Lazarus IDE
    2. Add your controls to the form (below the TitleBar)
    3. Customize TitleBar actions, title, leading icon
    4. Build and run (F9)
}

interface

uses
  Classes, SysUtils, Forms, Controls,
  FRMaterial3Base, FRMaterial3TitleBar, FRMaterialTheme, FRMaterialThemeManager;

type

  { TFmMain }

  TFmMain = class(TFRMaterialForm)
  private
    FThemeManager: TFRMaterialThemeManager;
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  FmMain: TFmMain;

implementation

constructor TFmMain.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);

  { Window settings }
  Caption     := 'My MD3 Application';
  Width       := 1024;
  Height      := 640;
  Position    := poScreenCenter;

  { Theme manager — controls palette, dark mode, density globally }
  FThemeManager := TFRMaterialThemeManager.Create(Self);
  FThemeManager.Palette  := mpBaseline;
  FThemeManager.DarkMode := False;

  { TitleBar is created automatically by TFRMaterialForm.
    Customize it here: }
  TitleBar.Title := Caption;
  // TitleBar.LeadingIcon := imMenu;
  // TitleBar.Buttons := [tbbMinimize, tbbMaximize, tbbClose];

  { Add your controls below. They will appear under the TitleBar.
    Example:
      var Btn: TFRMaterialButton;
      Btn := TFRMaterialButton.Create(Self);
      Btn.Parent := Self;
      Btn.SetBounds(20, 60, 120, 40);
      Btn.Caption := 'Click me';
  }
end;

end.
