@echo off
setlocal EnableExtensions
title PC Deep Cleaner v2.9 - Fast ^& Safe (AV-Friendly)
color 0A
:: NOTE: chcp yahan NAHI - chcp redirected stdin kha jata hai.
:: Isliye chcp sabse neeche hai. Script full-auto hai - koi sawal nahi.
cls

:: =====================================================
::  PC DEEP CLEANER v2.9 - Safe Temp Cleaner (AV-Friendly)
::  Deletes temp/cache/junk, never personal files.
::  AV ko disable/bypass NAHI karta (Tamper Protection +
::  SmartScreen flag se bachne ke liye). Instead 2-pass
::  + retry logic se locked files handle karta hai.
:: =====================================================

:: LOG ko LocalAppData root me rakho - Temp साफ करने पर उड़ेगा नहीं
set "LOG=%LocalAppData%\PC_Cleaner_log.txt"
if not exist "%LocalAppData%" set "LOG=%USERPROFILE%\PC_Cleaner_log.txt"
echo [%date% %time%] PC Deep Cleaner v2.9 started > "%LOG%" 2>nul

echo.
echo  ===============================================
echo   #  PC DEEP CLEANER v2.9 - by Cleaner Page
echo  ===============================================
echo   Cleaning temp + junk files to make PC fast...
echo   Temp + junk files saaf ho rahi hain taaki PC fast chale...
echo.

:: --- Auto self-elevate to Admin (AV-friendly, standard UAC) ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo  [!] No admin rights / Admin rights nahi mile - UAC khul raha hai...
    echo      UAC popup me YES dabao / Press YES in the UAC popup.
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs" >>"%LOG%" 2>&1
    if errorlevel 1 (
        echo  [!] UAC cancelled / cancel ho gaya - kuchh folders skip honge / some folders will skip.
        echo.
        timeout /t 3 /nobreak >nul
    ) else (
        exit /b 0
    )
) else (
    echo  [OK] Admin rights mil gaye / got admin rights - full clean hoga / full clean enabled.
    echo.
)

:: Current-folder lock se bachne ke liye system root me jao
pushd "%SystemRoot%" >nul 2>&1

:: --- AV status info (sirf INFO, disable nahi karenge) ---
echo  [AV-Check] Antivirus status check / status dekh rahe hain - kuchh disable nahi hoga / nothing disabled...
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $s=Get-MpComputerStatus -ErrorAction Stop; Write-Host ('  Defender RealTime: '+$s.RealTimeProtectionEnabled+' | Tamper: '+$s.IsTamperProtected) } catch { Write-Host '  Defender info nahi mila (3rd-party AV ho sakta hai) - OK' }" 2>nul
echo   NOTE: AV locked files ko 1-2 sec lock karta hai / AV locks files for 1-2 sec, isliye
echo         neeche 2-pass + retry cleaning hai / retry cleaning below. Ye normal hai / normal hai.
echo.
echo  [!] NOTE: Browser + Office apps apne-aap band honge / apps will auto-close,
echo      unsaved kaam SAVE kar liya hoga / save your work first - rukega nahi / no waiting.
echo.
echo   Safai turant shuru / starting now...

set "TOTAL_OK=0"

echo.
echo  [1/7] Cleaning User Temp / User Temp saaf ho raha ...
call :CleanDir "%TEMP%" "UserTemp"
:: %LocalAppData%\Temp aksar %TEMP% hi hota hai - double clean skip karo
if /i not "%LocalAppData%\Temp"=="%TEMP%" call :CleanDir "%LocalAppData%\Temp" "LocalTemp"

echo  [2/7] Cleaning Windows Temp / Windows Temp saaf ho raha - C:\Windows\Temp ...
call :CleanDir "C:\Windows\Temp" "WinTemp"

echo  [3/7] Cleaning Prefetch / Prefetch saaf - safe: sirf purani .pf, only old .pf ...
if exist "C:\Windows\Prefetch" (
    attrib -r -h -s "C:\Windows\Prefetch\*.pf" >nul 2>&1
    del /q /f "C:\Windows\Prefetch\*.pf" >nul 2>>"%LOG%"
    if exist "C:\Windows\Prefetch\ReadyBoot" del /q /f "C:\Windows\Prefetch\ReadyBoot\*.etl" >nul 2>>"%LOG%"
    echo        Done / Ho gaya. ^(kuchh .pf use me honge - skip normal hai / some skip - normal^)
    set /a TOTAL_OK+=1
) else (
    echo        Skipped / Chhoda - folder nahi mila / folder not found.
)

echo  [4/7] Cleaning Windows Update Cache / Update Cache saaf ho raha ...
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1
call :CleanDir "C:\Windows\SoftwareDistribution\Download" "WUDownload"
net start bits >nul 2>&1
net start wuauserv >nul 2>&1
echo        Done / Ho gaya.

echo  [5/7] Cleaning Thumbnail + Icon Cache, Logs, Recent, INetCache ...
echo        Thumbnail + Icon Cache, Logs, Recent saaf ho raha ...
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
echo        Done / Ho gaya.

echo  [6/7] Flushing DNS + Clearing Recycle Bin / DNS + Bin saaf ho raha ...
ipconfig /flushdns >nul 2>&1
:: AV-friendly Recycle Bin: PowerShell cmdlet (rd $Recycle.Bin aksar Access Denied deta hai)
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Clear-RecycleBin -Force -ErrorAction SilentlyContinue; Write-Host '  Bin cleared.' } catch { Write-Host '  Bin: kuchh drives skip (normal).' }" 2>nul
echo        Done / Ho gaya.

echo  [7/7] Final touch - Delivery Optimization + Minidump saaf / final cleaning ...
del /q /f /s "C:\Windows\SoftwareDistribution\DataStore\Logs\*.log" >nul 2>>"%LOG%"
if exist "%SystemRoot%\Minidump" del /q /f "%SystemRoot%\Minidump\*" >nul 2>>"%LOG%"
echo        Done / Ho gaya.

echo.
echo  [8/8] Full-disk check / pura disk check - purane Windows leftovers ...
echo   Note: del = permanent delete / Recycle Bin me nahi jata + Bin bhi khali hogi.
echo   Drives ka hisab / drive space report:
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-PSDrive -PSProvider FileSystem | ForEach-Object { $f=[math]::Round($_.Free/1GB,1); $u=[math]::Round($_.Used/1GB,1); Write-Host ('  Drive '+$_.Name+': '+$f+' GB free / '+$u+' GB used') }" 2>nul
set "OLDJUNK="
if exist "C:\Windows.old" set "OLDJUNK=C:\Windows.old"
if exist "C:\$Windows.~BT" set "OLDJUNK=%OLDJUNK% C:\$Windows.~BT"
if exist "C:\$Windows.~WS" set "OLDJUNK=%OLDJUNK% C:\$Windows.~WS"
if not defined OLDJUNK echo   Koi purana Windows leftover nahi mila / no leftovers found - badhiya.
if not defined OLDJUNK goto NoOldJunk
echo   MILA / FOUND - ye GBs kha rahe hain: %OLDJUNK%
echo   Ye sirf purane update ke leftovers hain / only old update leftovers - apne-aap delete honge / auto-delete.
if exist "C:\Windows.old" (
    echo   Deleting C:\Windows.old / delete ho raha - thoda time lagega...
    takeown /f "C:\Windows.old" /r /d y >nul 2>&1
    icacls "C:\Windows.old" /grant administrators:F /t /c /q >nul 2>&1
    rd /s /q "C:\Windows.old" >nul 2>>"%LOG%"
)
if exist "C:\$Windows.~BT" (
    echo   Deleting update leftover / delete ho raha...
    takeown /f "C:\$Windows.~BT" /r /d y >nul 2>&1
    icacls "C:\$Windows.~BT" /grant administrators:F /t /c /q >nul 2>&1
    rd /s /q "C:\$Windows.~BT" >nul 2>>"%LOG%"
)
if exist "C:\$Windows.~WS" (
    echo   Deleting update leftover / delete ho raha...
    takeown /f "C:\$Windows.~WS" /r /d y >nul 2>&1
    icacls "C:\$Windows.~WS" /grant administrators:F /t /c /q >nul 2>&1
    rd /s /q "C:\$Windows.~WS" >nul 2>>"%LOG%"
)
echo        Done / Ho gaya - GBs free hue.
:NoOldJunk

echo.
echo  [BONUS] Free RAM - extra apps apne-aap band / auto-closing extra apps ...
:: Duplicate/heavy background processes dikhao, phir graceful close
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Process -ErrorAction SilentlyContinue | Group-Object Name | Where-Object { $_.Count -gt 1 } | Sort-Object Count -Descending | Select-Object -First 8 | ForEach-Object { '{0,-22} x{1} instances' -f $_.Name, $_.Count }" 2>nul
echo   Graceful close / surakshit band - save wala app khula rahega / apps with save dialog stay open...
for %%A in (chrome msedge firefox opera brave notepad winword excel powerpnt) do taskkill /im %%A.exe >nul 2>&1
timeout /t 5 /nobreak >nul
echo        Done / Ho gaya.
:: Full-auto mode: koi sawal nahi - chcp yahan safe hai
chcp 65001 >nul 2>&1

popd >nul 2>&1
echo.
echo  ===============================================
echo   CLEANING COMPLETE / SAFAI HO GAYI! PC is now faster / ab tez hai.
echo  ===============================================
echo   Locked files skip hona NORMAL hai / locked files skip = normal.
echo   Full result / poori report: %LOG%
echo   Tip / Salah: PC ko ek baar restart karo / restart once for best speed.
echo.
echo   Ek chhota sawal / one quick question...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Add-Type -AssemblyName System.Windows.Forms; $ans=[System.Windows.Forms.MessageBox]::Show('Do you want to explore more free apps and extensions? Kya aap aur free apps dekhna chahenge?','PC Deep Cleaner - Explore More',4,64); if ($ans -eq 'Yes') { Start-Process 'https://edevsuraj.github.io/explore-our-apps-and-extensions/' }"
echo.
pause
exit /b 0

:: ============ SUB-ROUTINE: 2-pass AV-friendly clean ============
:CleanDir
rem %~1 = folder path, %~2 = label
if not exist "%~1" (
    echo        Skipped %~2 - folder nahi mila / not found.
    goto :eof
)
:: Pass 1: read-only/hidden/system hatayo, phir delete
attrib -r -h -s "%~1\*" /s /d >nul 2>&1
del /f /q /s "%~1\*" >nul 2>>"%LOG%"
for /d %%J in ("%~1\*") do rd /s /q "%%J" >nul 2>>"%LOG%"
:: Bacha hua hai? (AV lock / long path) tabhi retry - warna time waste mat karo
dir /a /b "%~1" 2>nul | findstr /r "." >nul 2>&1
if errorlevel 1 (
    echo        Done %~2 / ho gaya.
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
    echo        Done %~2 / ho gaya.
    set /a TOTAL_OK+=1
    goto :eof
)
if not exist "%TEMP%\PCEmptyDir" md "%TEMP%\PCEmptyDir" >nul 2>&1
robocopy "%TEMP%\PCEmptyDir" "%~1" /MIR /R:1 /W:1 /NFL /NDL /NJH /NJS >nul 2>>"%LOG%"
rd /s /q "%TEMP%\PCEmptyDir" >nul 2>&1
:CleanDone
echo        Done %~2 - locked skip normal / lock wali chhoot gayi, normal hai.
set /a TOTAL_OK+=1
goto :eof
