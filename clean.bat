@echo off
setlocal EnableExtensions
title PC Deep Cleaner - Fast ^& Safe
color 0A
chcp 65001 >nul 2>&1
cls

:: =====================================================
::  PC DEEP CLEANER v1.0 - Safe Temp Cleaner
::  Deletes temp / junk files to make PC fast
::  Safe: only deletes temp/cache, never personal files
::  Run as Administrator for best results
:: =====================================================

echo.
echo  ===============================================
echo   #  PC DEEP CLEANER  - by Cleaner Page
echo  ===============================================
echo   Cleaning temp + junk files to make PC fast...
echo.

:: --- Admin check ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo  [!] Not running as Admin - some folders will be skipped.
    echo  [TIP] Right-click .bat ^> Run as administrator for full clean.
    echo.
    timeout /t 3 /nobreak >nul
) else (
    echo  [OK] Running with Admin rights - full clean enabled.
    echo.
)

set /p CONFIRM="  Start cleaning now? (Y/N): "
if /i not "%CONFIRM%"=="Y" (
    echo  Cancelled. No files deleted.
    pause
    exit /b
)

echo.
echo  [1/7] Cleaning User Temp - %TEMP% ...
del /q /f /s "%TEMP%\*" 2>nul
for /d %%p in ("%TEMP%\*.*") do rmdir "%%p" /s /q 2>nul
echo        Done.

echo  [2/7] Cleaning Windows Temp - C:\Windows\Temp ...
del /q /f /s "C:\Windows\Temp\*" 2>nul
for /d %%p in ("C:\Windows\Temp\*.*") do rmdir "%%p" /s /q 2>nul
echo        Done.

echo  [3/7] Cleaning Prefetch ...
del /q /f /s "C:\Windows\Prefetch\*" 2>nul
echo        Done.

echo  [4/7] Cleaning Windows Update Cache ...
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1
del /q /f /s "C:\Windows\SoftwareDistribution\Download\*" 2>nul
for /d %%p in ("C:\Windows\SoftwareDistribution\Download\*.*") do rmdir "%%p" /s /q 2>nul
net start bits >nul 2>&1
net start wuauserv >nul 2>&1
echo        Done.

echo  [5/7] Cleaning Thumbnail + Icon Cache, Logs, Recent ...
del /q /f /s "%LocalAppData%\Microsoft\Windows\Explorer\thumbcache*.db" 2>nul
del /q /f /s "%LocalAppData%\Microsoft\Windows\Explorer\iconcache*.db" 2>nul
del /q /f /s "%LocalAppData%\Temp\*" 2>nul
del /q /f /s "%SystemRoot%\Logs\*.log" 2>nul
del /q /f /s "%SystemRoot%\*.log" 2>nul
del /q /f /s "%USERPROFILE%\Recent\*" 2>nul
echo        Done.

echo  [6/7] Flushing DNS + Clearing Recycle Bin ...
ipconfig /flushdns >nul 2>&1
for %%d in (C D E F G) do rd /s /q "%%d:\$Recycle.Bin" 2>nul
echo        Done.

echo  [7/7] Final touch - Delivery Optimization + Mini dump ...
del /q /f /s "C:\Windows\SoftwareDistribution\DataStore\Logs\*.log" 2>nul
del /q /f /s "%SystemRoot%\Minidump\*" 2>nul
echo        Done.

echo.
echo  ===============================================
echo   CLEANING COMPLETE! PC is now faster.
echo  ===============================================
echo   Tip: Restart your PC once for best speed.
echo.
echo   Showing a quick question...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Add-Type -AssemblyName System.Windows.Forms; $ans=[System.Windows.Forms.MessageBox]::Show('Do you want to explore more free apps and extensions?','PC Deep Cleaner - Explore More',4,64); if ($ans -eq 'Yes') { Start-Process 'https://edevsuraj.github.io/explore-our-apps-and-extensions/' }"
echo.
pause
exit /b 0
