# Cross-Platform Compatibility Guide

## Overview
FRComponents is designed to be fully cross-platform compatible with Windows and Linux systems. This document outlines the platform-specific implementations and compatibility considerations.

## Current Status
- **Windows**: Full support with all features
- **Linux**: Full support with graceful degradation of Windows-specific features
- **Cross-platform**: Core components work identically on both platforms

## Platform-Specific Features

### Windows-Only Features
These features are only available on Windows and are gracefully disabled on Linux:

#### 1. DWM Shadow (FRMaterial3TitleBar.pas)
- **Windows**: Native Desktop Window Manager shadow effects
- **Linux**: No shadow (feature disabled)
- **Implementation**: `{$IFDEF MSWINDOWS}` blocks around DWM API calls

#### 2. Window Subclassing (FRMaterial3TitleBar.pas)
- **Windows**: ComCtl32 subclassing for custom window behavior
- **Linux**: LCL default window behavior
- **Implementation**: `{$IFDEF MSWINDOWS}` blocks around subclassing code

#### 3. Rounded Window Regions
- **Windows**: `CreateRoundRectRgn` and `SetWindowRgn` API calls
- **Files affected**: FRMaterial3Dialog.pas, FRMaterial3Combo.pas, FRMaterial3Snackbar.pas
- **Linux**: Standard rectangular windows (feature disabled)

#### 4. Screen Capture (FRMaterial3Dialog.pas)
- **Windows**: `BitBlt` with `GetDC(0)` for screen capture
- **Linux**: Alternative method may be needed for full functionality

## Cross-Platform Implementations

### Message Handling
- **Fixed**: `LParamHi`/`LParamLo` replaced with `HiWord()`/`LoWord()`
- **File**: FRMaterial3PageControl.pas (line 682)
- **Status**: Fully cross-platform

### Form Behavior
- **Windows**: Custom window chrome with DWM effects
- **Linux**: Standard LCL window decorations
- **Compatibility**: All core functionality preserved

## Conditional Compilation Directives Used

### MSWINDOWS
```pascal
{$IFDEF MSWINDOWS}
  // Windows-specific code
{$ENDIF}
```

### WINDOWS
```pascal
{$IFDEF WINDOWS}
  // Windows-specific code
{$ENDIF}
```

## Dependencies

### Core Dependencies (Cross-platform)
- **LCL**: Lazarus Component Library
- **FCL**: Free Component Library  
- **BGRABitmapPack**: Graphics rendering library

### Windows-Only Dependencies
- **comctl32.dll**: Common controls
- **user32.dll**: User interface APIs
- **gdi32.dll**: Graphics device interface

## Testing Recommendations

### Windows Testing
- All features should work as designed
- DWM effects and custom window chrome active
- Rounded corners and shadows visible

### Linux Testing  
- Core components should work identically
- Windows-specific features gracefully disabled
- No compilation errors or runtime crashes

## Migration Notes

When moving between platforms:
1. **No code changes required** for core functionality
2. **Windows-specific features** automatically disabled on Linux
3. **Compilation**: Use appropriate Lazarus cross-compiler
4. **Dependencies**: Ensure BGRABitmapPack is installed on target platform

## Future Enhancements

### Potential Linux-Specific Features
- GTK+ theme integration
- Compositor shadow effects
- Rounded window regions via X11/Wayland

### Cross-Platform Improvements
- Unified shadow implementation
- Platform-agnostic window regions
- Enhanced theme management

## Troubleshooting

### Common Issues
1. **Compilation errors**: Check for missing dependencies
2. **Missing features**: Verify Windows-specific code is properly conditionally compiled
3. **Runtime errors**: Ensure proper Lazarus version compatibility

### Debug Tips
- Use `{$IFDEF MSWINDOWS}` to identify platform-specific code paths
- Test core functionality separately from Windows-specific features
- Verify BGRABitmapPack installation on target platform

## Conclusion

FRComponents successfully maintains cross-platform compatibility while providing enhanced features on Windows. The conditional compilation approach ensures:
- **Zero configuration** needed when switching platforms
- **Graceful degradation** of Windows-specific features on Linux
- **Identical core behavior** across all supported platforms

The library is production-ready for both Windows and Linux development environments.
