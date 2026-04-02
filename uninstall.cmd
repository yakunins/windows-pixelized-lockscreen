:: removes Scheduled Task and re-enables native Win+L
@echo off
setlocal EnableExtensions DisableDelayedExpansion

:: Re-enable native Win+L
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableLockWorkstation /t REG_DWORD /d 0 /f
echo Win+L re-enabled.

set PS=powershell.exe -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile
set TaskName='PixelizedLockscreen'

set DeleteTask="try{Unregister-ScheduledTask -TaskName %TaskName% -Confirm:$false;Write-Host 'UnregisterTask: PixelizedLockscreen, done.';}catch{Write-Host 'UnregisterTask: PixelizedLockscreen, error:';Write-Host $_;}"
%PS% -Command %DeleteTask%

:prompt
set /P OPEN=Open Task Scgheduler? Y/[N]
if /I "%OPEN%" neq "Y" goto end
start Taskschd.msc
:end

endlocal
