unit FRMaterial3Divider;

{$mode objfpc}{$H+}

{ Material Design 3 — Divider and GroupBox.

  TFRMaterialDivider  — Simple 1dp line divider
  TFRMaterialGroupBox — Container with MD3 styling, rounded corners, title

  License: LGPL v3
}

interface

uses
  Classes, SysUtils, Controls, Graphics, ExtCtrls,
  {$IFDEF FPC} LResources, {$ENDIF}
  BGRABitmap, BGRABitmapTypes, FRMaterial3Base;

type
  TFRMDDividerOrientation = (doHorizontal, doVertical);

  { ── TFRMaterialDivider ── }

  TFRMaterialDivider = class(TFRMaterial3Graphic)
  private
    FOrientation: TFRMDDividerOrientation;
    FInsetStart: Integer;
    FInsetEnd: Integer;
    procedure SetOrientation(AValue: TFRMDDividerOrientation);
    procedure SetInsetStart(AValue: Integer);
    procedure SetInsetEnd(AValue: Integer);
  protected
    procedure Paint; override;
    class function GetControlClassDefaultSize: TSize; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Orientation: TFRMDDividerOrientation read FOrientation write SetOrientation default doHorizontal;
    property InsetStart: Integer read FInsetStart write SetInsetStart default 0;
    property InsetEnd: Integer read FInsetEnd write SetInsetEnd default 0;
    property Align;
    property Visible;
  end;

  { ── TFRMaterialGroupBox ── }

  TFRMaterialGroupBox = class(TCustomPanel)
  private
    FBorderRadius: Integer;
    FShowBorder: Boolean;
    procedure SetBorderRadius(AValue: Integer);
    procedure SetShowBorder(AValue: Boolean);
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property BorderRadius: Integer read FBorderRadius write SetBorderRadius default 12;
    property ShowBorder: Boolean read FShowBorder write SetShowBorder default True;
    property Align;
    property Anchors;
    property Caption;
    property Color;
    property Constraints;
    property Enabled;
    property Font;
    property Visible;
    property OnClick;
    property OnResize;
  end;

procedure Register;

implementation

uses Math;

procedure Register;
begin
  {$IFDEF FPC}
    {$I icons\frmaterialdivider_icon.lrs}
    {$I icons\frmaterialgroupbox_icon.lrs}
  {$ENDIF}
  RegisterComponents('BGRA Controls', [TFRMaterialDivider, TFRMaterialGroupBox]);
end;

{ ── TFRMaterialDivider ── }

constructor TFRMaterialDivider.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FOrientation := doHorizontal;
  FInsetStart := 0;
  FInsetEnd := 0;
  with GetControlClassDefaultSize do
    SetInitialBounds(0, 0, cx, cy);
end;

class function TFRMaterialDivider.GetControlClassDefaultSize: TSize;
begin
  Result.cx := 200;
  Result.cy := 1;
end;

procedure TFRMaterialDivider.SetOrientation(AValue: TFRMDDividerOrientation);
begin
  if FOrientation = AValue then Exit;
  FOrientation := AValue;
  if AValue = doHorizontal then
    Height := 1
  else
    Width := 1;
  Invalidate;
end;

procedure TFRMaterialDivider.SetInsetStart(AValue: Integer);
begin
  if FInsetStart = AValue then Exit;
  FInsetStart := AValue;
  Invalidate;
end;

procedure TFRMaterialDivider.SetInsetEnd(AValue: Integer);
begin
  if FInsetEnd = AValue then Exit;
  FInsetEnd := AValue;
  Invalidate;
end;

procedure TFRMaterialDivider.Paint;
var
  bmp: TBGRABitmap;
  c: TBGRAPixel;
begin
  bmp := TBGRABitmap.Create(Width, Height, BGRAPixelTransparent);
  try
    c := ColorToBGRA(ColorToRGB(MD3Colors.OutlineVariant));
    if FOrientation = doHorizontal then
      bmp.DrawLineAntialias(FInsetStart, 0, Width - FInsetEnd, 0, c, 1.0)
    else
      bmp.DrawLineAntialias(0, FInsetStart, 0, Height - FInsetEnd, c, 1.0);
    bmp.Draw(Canvas, 0, 0, False);
  finally
    bmp.Free;
  end;
end;

{ ── TFRMaterialGroupBox ── }

constructor TFRMaterialGroupBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBorderRadius := 12;
  FShowBorder := True;
  Width := 250;
  Height := 150;
  BevelOuter := bvNone;
  BevelInner := bvNone;
  Color := MD3Colors.SurfaceContainerLow;
  Font.Size := 10;
  Font.Color := MD3Colors.OnSurface;
end;

procedure TFRMaterialGroupBox.SetBorderRadius(AValue: Integer);
begin
  if FBorderRadius = AValue then Exit;
  FBorderRadius := AValue;
  Invalidate;
end;

procedure TFRMaterialGroupBox.SetShowBorder(AValue: Boolean);
begin
  if FShowBorder = AValue then Exit;
  FShowBorder := AValue;
  Invalidate;
end;

procedure TFRMaterialGroupBox.Paint;
var
  bmp: TBGRABitmap;
  capH, capW: Integer;
  aRect: TRect;
begin
  bmp := TBGRABitmap.Create(Width, Height, BGRAPixelTransparent);
  try
    { Background }
    MD3FillRoundRect(bmp, 0, 0, Width - 1, Height - 1, FBorderRadius, Color);

    { Border }
    if FShowBorder then
      MD3RoundRect(bmp, 0.5, 0.5, Width - 1.5, Height - 1.5, FBorderRadius,
        MD3Colors.OutlineVariant, 1.0);

    bmp.Draw(Canvas, 0, 0, False);
  finally
    bmp.Free;
  end;

  { Caption }
  if Caption <> '' then
  begin
    Canvas.Font := Self.Font;
    Canvas.Font.Style := [fsBold];
    capH := Canvas.TextHeight(Caption);
    capW := Canvas.TextWidth(Caption);
    aRect := Rect(16, 12, 16 + capW, 12 + capH);
    MD3DrawText(Canvas, Caption, aRect, MD3Colors.OnSurface, taLeftJustify, False);
  end;
end;

end.
