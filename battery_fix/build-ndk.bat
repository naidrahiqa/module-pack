@echo off
REM Battery Fix — Windows NDK Cross-Compile Build Script
REM Requires: Android NDK at C:\android-ndk-r27c, cmake + ninja in PATH

set NDK=C:\android-ndk-r27c
set TOOLCHAIN=%NDK%\build\cmake\android.toolchain.cmake
set CMAKE_BIN=D:\Dev\cmake\cmake-4.2.3-windows-x86_64\bin\cmake.exe
set NINJA=D:\Dev\cmake\ninja.exe
set SRC=%~dp0src
set BUILD=%~dp0build
set OUT=%~dp0lib\arm64-v8a

if not exist "%NDK%" (
    echo ERROR: NDK not found at %NDK%
    exit /b 1
)
if not exist "%CMAKE_BIN%" (
    echo ERROR: cmake not found at %CMAKE_BIN%
    exit /b 1
)
if not exist "%NINJA%" (
    echo ERROR: ninja not found at %NINJA%
    exit /b 1
)

echo === Battery Fix C Build ===
echo NDK: %NDK%

if not exist "%BUILD%" mkdir "%BUILD%"
if not exist "%OUT%" mkdir "%OUT%"

cd "%BUILD%"

"%CMAKE_BIN%" -DCMAKE_TOOLCHAIN_FILE=%TOOLCHAIN% ^
      -DANDROID_ABI=arm64-v8a ^
      -DANDROID_PLATFORM=android-28 ^
      -DCMAKE_BUILD_TYPE=Release ^
      -DCMAKE_MAKE_PROGRAM=%NINJA% ^
      -G Ninja ^
      "%SRC%"

if errorlevel 1 (
    echo ERROR: cmake configure failed
    cd "%~dp0"
    exit /b 1
)

"%CMAKE_BIN%" --build . -j8

if errorlevel 1 (
    echo ERROR: cmake build failed
    cd "%~dp0"
    exit /b 1
)

copy /Y battery_daemon "%OUT%\battery_daemon" >nul 2>&1

cd "%~dp0"

echo.
echo === BUILD SUCCESS ===
dir "%OUT%\battery_daemon"
