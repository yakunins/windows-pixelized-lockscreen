:: removes Scheduled Task
@echo off
setlocal EnableExtensions DisableDelayedExpansion

set PS=powershell.exe -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile
set TaskName='PostponeWinL'
set DeleteTask="try{Unregister-ScheduledTask -TaskName %TaskName% -Confirm:$false;Write-Host 'UnregisterTask: PixelizedLockscreen, done.';}catch{Write-Host 'UnregisterTask: PixelizedLockscreen, error:';Write-Host $_;}"
%PS% -Command %DeleteTask%

:prompt
set /P OPEN=Open Task Scgheduler? Y/[N]
if /I "%OPEN%" neq "Y" goto end
start Taskschd.msc
:end

endlocal
