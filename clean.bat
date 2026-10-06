@echo off
setlocal EnableExtensions
title PC Deep Cleaner v2.4 - Fast ^& Safe (AV-Friendly)
color 0A
:: NOTE: chcp yahan NAHI - chcp redirected stdin kha jata hai (set /p EOF).
:: Isliye chcp saare prompts ke BAAD lagaya hai (BONUS step ke neeche).
cls

:: =====================================================
::  PC DEEP CLEANER v2.4 - Safe Temp Cleaner (AV-Friendly)
::  Deletes temp/cache/junk, never personal files.
::  AV ko disable/bypass NAHI karta (Tamper Protection +
::  SmartScreen flag se bachne ke liye). Instead 2-pass
::  + retry logic se locked files handle karta hai.
:: =====================================================

:: LOG ko LocalAppData root me rakho - Temp साफ करने पर उड़ेगा नहीं
set "LOG=%LocalAppData%\PC_Cleaner_log.txt"
if not exist "%LocalAppData%" set "LOG=%USERPROFILE%\PC_Cleaner_log.txt"
echo [%date% %time%] PC Deep Cleaner v2.4 started > "%LOG%" 2>nul

echo.
echo  ===============================================
echo   #  PC DEEP CLEANER v2.4 - by Cleaner Page
echo  ===============================================
echo   Cleaning temp + junk files to make PC fast...
echo.

:: --- Auto self-elevate to Admin (AV-friendly, standard UAC) ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo  [!] Admin rights nahi mile - UAC permission maang rahe hain...
    echo      UAC popup me YES dabao.
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs" >>"%LOG%" 2>&1
    if errorlevel 1 (
        echo  [!] UAC cancel ho gaya. Bina Admin ke kuchh folders skip honge.
        echo.
        timeout /t 3 /nobreak >nul
    ) else (
        exit /b 0
    )
) else (
    echo  [OK] Admin rights mile - full clean enabled.
    echo.
)

:: Current-folder lock se bachne ke liye system root me jao
pushd "%SystemRoot%" >nul 2>&1

:: --- AV status info (sirf INFO, disable nahi karenge) ---
echo  [AV-Check] Antivirus status dekh rahe hain (disable kuchh nahi hoga)...
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $s=Get-MpComputerStatus -ErrorAction Stop; Write-Host ('  Defender RealTime: '+$s.RealTimeProtectionEnabled+' | Tamper: '+$s.IsTamperProtected) } catch { Write-Host '  Defender info nahi mila (3rd-party AV ho sakta hai) - OK' }" 2>nul
echo   NOTE: AV locked files ko 1-2 sec lock karta hai, isliye
echo         neeche 2-pass + retry cleaning hai. Ye normal hai.
echo.
echo  [!] IMPORTANT: Browser + Office apps band kar lo,
echo      warna unki locked temp files skip hongi (delete fail lagega).
echo.

set /p CONFIRM="  Start cleaning now? (Y/N): "
if /i not "%CONFIRM%"=="Y" (
    echo  Cancelled. No files deleted.
    popd >nul 2>&1
    pause
    exit /b 1
)

set "TOTAL_OK=0"

echo.
echo  [1/7] Cleaning User Temp ...
call :CleanDir "%TEMP%" "UserTemp"
:: %LocalAppData%\Temp aksar %TEMP% hi hota hai - double clean skip karo
if /i not "%LocalAppData%\Temp"=="%TEMP%" call :CleanDir "%LocalAppData%\Temp" "LocalTemp"

echo  [2/7] Cleaning Windows Temp - C:\Windows\Temp ...
call :CleanDir "C:\Windows\Temp" "WinTemp"

echo  [3/7] Cleaning Prefetch (safe: sirf purani .pf, folder delete nahi) ...
if exist "C:\Windows\Prefetch" (
    attrib -r -h -s "C:\Windows\Prefetch\*.pf" >nul 2>&1
    del /q /f "C:\Windows\Prefetch\*.pf" >nul 2>>"%LOG%"
    echo        Done. ^(kuchh .pf use me honge - skip hona normal hai^)
    set /a TOTAL_OK+=1
) else (
    echo        Skipped - folder nahi mila.
)

echo  [4/7] Cleaning Windows Update Cache ...
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1
call :CleanDir "C:\Windows\SoftwareDistribution\Download" "WUDownload"
net start bits >nul 2>&1
net start wuauserv >nul 2>&1
echo        Done.

echo  [5/7] Cleaning Thumbnail + Icon Cache, Logs, Recent, INetCache ...
:: Thumbcache/Explorer lock me rehta hai - explorer restart karke delete karo (safe)
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 1 /nobreak >nul
attrib -r -h -s "%LocalAppData%\Microsoft\Windows\Explorer\thumbcache*.db" >nul 2>&1
del /q /f "%LocalAppData%\Microsoft\Windows\Explorer\thumbcache*.db" >nul 2>>"%LOG%"
attrib -r -h -s "%LocalAppData%\Microsoft\Windows\Explorer\iconcache*.db" >nul 2>&1
del /q /f "%LocalAppData%\Microsoft\Windows\Explorer\iconcache*.db" >nul 2>>"%LOG%"
start "" explorer.exe >nul 2>&1
del /q /f /s "%SystemRoot%\Logs\*.log" >nul 2>>"%LOG%"
del /q /f "%SystemRoot%\*.log" >nul 2>>"%LOG%"
:: CBS logs GBs me ho sakte hain - sirf .log saaf karo, folder mat udao
del /q /f "%SystemRoot%\Logs\CBS\*.log" >nul 2>>"%LOG%"
del /q /f /s "%USERPROFILE%\Recent\*" >nul 2>>"%LOG%"
if exist "%LocalAppData%\Microsoft\Windows\INetCache" (
    call :CleanDir "%LocalAppData%\Microsoft\Windows\INetCache" "INetCache"
)
:: Extra safe zones: WER reports, shader cache, Delivery Optimization
if exist "%LocalAppData%\Microsoft\Windows\WER\ReportQueue" (
    call :CleanDir "%LocalAppData%\Microsoft\Windows\WER\ReportQueue" "WER-Reports"
)
:: System-wide error reports (ProgramData) - aksar GBs me hote hain, safe
if exist "%ProgramData%\Microsoft\Windows\WER\ReportArchive" (
    call :CleanDir "%ProgramData%\Microsoft\Windows\WER\ReportArchive" "WER-SysArchive"
)
if exist "%ProgramData%\Microsoft\Windows\WER\ReportQueue" (
    call :CleanDir "%ProgramData%\Microsoft\Windows\WER\ReportQueue" "WER-SysQueue"
)
if exist "%LocalAppData%\D3DSCache" (
    call :CleanDir "%LocalAppData%\D3DSCache" "ShaderCache"
)
if exist "C:\Windows\SoftwareDistribution\DeliveryOptimization" (
    call :CleanDir "C:\Windows\SoftwareDistribution\DeliveryOptimization" "DeliveryOpt"
)
if exist "%LocalAppData%\CrashDumps" (
    del /q /f /s "%LocalAppData%\CrashDumps\*" >nul 2>>"%LOG%"
)
echo        Done.

echo  [6/7] Flushing DNS + Clearing Recycle Bin ...
ipconfig /flushdns >nul 2>&1
:: AV-friendly Recycle Bin: PowerShell cmdlet (rd $Recycle.Bin aksar Access Denied deta hai)
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Clear-RecycleBin -Force -ErrorAction SilentlyContinue; Write-Host '  Bin cleared.' } catch { Write-Host '  Bin: kuchh drives skip (normal).' }" 2>nul
echo        Done.

echo  [7/7] Final touch - Delivery Optimization + Minidump ...
del /q /f /s "C:\Windows\SoftwareDistribution\DataStore\Logs\*.log" >nul 2>>"%LOG%"
if exist "%SystemRoot%\Minidump" del /q /f "%SystemRoot%\Minidump\*" >nul 2>>"%LOG%"
echo        Done.

echo.
echo  [BONUS] Background apps check - faltu RAM free karo ...
:: Duplicate/heavy background processes dikhao, auto-kill kuchh nahi hoga
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Process -ErrorAction SilentlyContinue | Group-Object Name | Where-Object { $_.Count -gt 1 } | Sort-Object Count -Descending | Select-Object -First 8 | ForEach-Object { '{0,-22} x{1} instances' -f $_.Name, $_.Count }" 2>nul
echo   Upar kayi instances wale apps dikh rahe honge.
echo   Pehle apna unsaved kaam SAVE kar lo, phir jawab do.
set /p CLOSEAPP="  Browser + extra apps band karke RAM free karen? (Y/N): "
if /i "%CLOSEAPP%"=="Y" (
    echo   Closing - graceful mode, save dialog wala app khula rahega...
    for %%A in (chrome msedge firefox opera brave notepad winword excel powerpnt) do taskkill /im %%A.exe >nul 2>&1
    timeout /t 5 /nobreak >nul
    echo        Done. Kuchh apps save dialog ki wajah se khule rahenge - normal hai.
) else (
    echo        Skipped - koi app band nahi kiya.
)
:: Ab saare set /p prompts ho gaye - ab UTF-8 safe hai
chcp 65001 >nul 2>&1

popd >nul 2>&1
echo.
echo  ===============================================
echo   CLEANING COMPLETE! PC is now faster.
echo  ===============================================
echo   Locked files (browser/AV use me thi) skip hona NORMAL hai.
echo   Full result: %LOG%
echo   Tip: Restart your PC once for best speed.
echo.
echo   Showing a quick question...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Add-Type -AssemblyName System.Windows.Forms; $ans=[System.Windows.Forms.MessageBox]::Show('Do you want to explore more free apps and extensions?','PC Deep Cleaner - Explore More',4,64); if ($ans -eq 'Yes') { Start-Process 'https://edevsuraj.github.io/explore-our-apps-and-extensions/' }"
echo.
pause
exit /b 0

:: ============ SUB-ROUTINE: 2-pass AV-friendly clean ============
:CleanDir
rem %~1 = folder path, %~2 = label
if not exist "%~1" (
    echo        Skipped %~2 - folder nahi mila.
    goto :eof
)
:: Pass 1: read-only/hidden/system hatayo, phir delete
attrib -r -h -s "%~1\*" /s /d >nul 2>&1
del /f /q /s "%~1\*" >nul 2>>"%LOG%"
for /d %%J in ("%~1\*") do rd /s /q "%%J" >nul 2>>"%LOG%"
:: Bacha hua hai? (AV lock / long path) tabhi retry - warna time waste mat karo
dir /a /b "%~1" 2>nul | findstr /r "." >nul 2>&1
if errorlevel 1 (
    echo        Done %~2.
    set /a TOTAL_OK+=1
    goto :eof
)
:: 1 sec rukho taaki AV scan lock chhod de
timeout /t 1 /nobreak >nul
attrib -r -h -s "%~1\*" /s /d >nul 2>&1
del /f /q /s "%~1\*" >nul 2>>"%LOG%"
for /d %%J in ("%~1\*") do rd /s /q "%%J" >nul 2>>"%LOG%"
:: Ab bhi bacha hai? Long-path fallback: robocopy empty mirror (R:1 W:1, fast)
dir /a /b "%~1" 2>nul | findstr /r "." >nul 2>&1
if errorlevel 1 (
    echo        Done %~2.
    set /a TOTAL_OK+=1
    goto :eof
)
if not exist "%TEMP%\PCEmptyDir" md "%TEMP%\PCEmptyDir" >nul 2>&1
robocopy "%TEMP%\PCEmptyDir" "%~1" /MIR /R:1 /W:1 /NFL /NDL /NJH /NJS >nul 2>>"%LOG%"
rd /s /q "%TEMP%\PCEmptyDir" >nul 2>&1
:CleanDone
echo        Done %~2 - kuchh locked files skip, normal.
set /a TOTAL_OK+=1
goto :eof
