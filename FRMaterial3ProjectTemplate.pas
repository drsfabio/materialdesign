unit FRMaterial3ProjectTemplate;

{$mode objfpc}{$H+}

{ Registers "MD3 Application" in the Lazarus IDE under File > New > Project.
  Creates a minimal project with TFRMaterialForm as the main form. }

interface

uses
  Classes, SysUtils, ProjectIntf, LazIDEIntf, Controls, Forms;

type

  { TFRMaterialFormProjectDescriptor }

  TFRMaterialFormProjectDescriptor = class(TProjectDescriptor)
  public
    constructor Create; override;
    function GetLocalizedName: string; override;
    function GetLocalizedDescription: string; override;
    function InitProject(AProject: TLazProject): TModalResult; override;
    function CreateStartFiles({%H-}AProject: TLazProject): TModalResult; override;
  end;

procedure Register;

implementation

const
  SProjectName = 'MD3 Application';
  SProjectDesc = 'A Material Design 3 application with TFRMaterialForm'
    + ' (borderless window, custom TitleBar, DWM shadow, rounded corners).';

  { Source templates }
  SLprSource =
    'program md3app;'                                                + LineEnding +
    ''                                                               + LineEnding +
    '{$mode objfpc}{$H+}'                                            + LineEnding +
    ''                                                               + LineEnding +
    'uses'                                                           + LineEnding +
    '  {$IFDEF UNIX}cthreads,{$ENDIF}'                              + LineEnding +
    '  Interfaces, Classes, SysUtils, Forms, Controls,'              + LineEnding +
    '  FRMaterial3Base, FRMaterial3TitleBar,'                         + LineEnding +
    '  FRMaterialTheme, FRMaterialThemeManager;'                     + LineEnding +
    ''                                                               + LineEnding +
    'type'                                                           + LineEnding +
    '  TFmMain = class(TFRMaterialForm)'                             + LineEnding +
    '  private'                                                      + LineEnding +
    '    FThemeManager: TFRMaterialThemeManager;'                     + LineEnding +
    '  public'                                                       + LineEnding +
    '    constructor Create(AOwner: TComponent); override;'          + LineEnding +
    '  end;'                                                         + LineEnding +
    ''                                                               + LineEnding +
    'var'                                                            + LineEnding +
    '  FmMain: TFmMain;'                                             + LineEnding +
    ''                                                               + LineEnding +
    'constructor TFmMain.Create(AOwner: TComponent);'                + LineEnding +
    'begin'                                                          + LineEnding +
    '  inherited CreateNew(AOwner);'                                 + LineEnding +
    '  Caption  := ''My MD3 Application'';'                          + LineEnding +
    '  Width    := 1024;'                                            + LineEnding +
    '  Height   := 640;'                                             + LineEnding +
    '  Position := poScreenCenter;'                                  + LineEnding +
    '  FThemeManager := TFRMaterialThemeManager.Create(Self);'       + LineEnding +
    '  TitleBar.Title := Caption;'                                   + LineEnding +
    'end;'                                                           + LineEnding +
    ''                                                               + LineEnding +
    'begin'                                                          + LineEnding +
    '  Application.Scaled := True;'                                  + LineEnding +
    '  Application.Initialize;'                                      + LineEnding +
    '  Application.CreateForm(TFmMain, FmMain);'                     + LineEnding +
    '  Application.Run;'                                             + LineEnding +
    'end.';

{ TFRMaterialFormProjectDescriptor }

constructor TFRMaterialFormProjectDescriptor.Create;
begin
  inherited Create;
  Name := SProjectName;
end;

function TFRMaterialFormProjectDescriptor.GetLocalizedName: string;
begin
  Result := SProjectName;
end;

function TFRMaterialFormProjectDescriptor.GetLocalizedDescription: string;
begin
  Result := SProjectDesc;
end;

function TFRMaterialFormProjectDescriptor.InitProject(
  AProject: TLazProject): TModalResult;
var
  MainFile: TLazProjectFile;
begin
  Result := inherited InitProject(AProject);
  if Result <> mrOk then Exit;

  { Main program file }
  MainFile := AProject.CreateProjectFile('md3app.lpr');
  MainFile.IsPartOfProject := True;
  AProject.AddFile(MainFile, False);
  AProject.MainFileID := 0;
  AProject.MainFile.SetSourceText(SLprSource, True);

  { Project settings }
  AProject.Title := 'MD3 Application';
  AProject.LazCompilerOptions.Win32GraphicApp := True;
  AProject.AddPackageDependency('LCL');
  AProject.AddPackageDependency('FRComponents');

  Result := mrOk;
end;

function TFRMaterialFormProjectDescriptor.CreateStartFiles(
  {%H-}AProject: TLazProject): TModalResult;
begin
  { Single-file template — everything is in the .lpr }
  Result := mrOk;
end;

{ Registration }

procedure Register;
begin
  RegisterProjectDescriptor(TFRMaterialFormProjectDescriptor.Create);
end;

end.
