:: creates at-startup Scheduled Task 
@echo off
setlocal EnableExtensions DisableDelayedExpansion

set PS=powershell.exe -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile
set TaskName='PixelizedLockscreen'
set CurrentUser=%USERDOMAIN%\%USERNAME%
set CurrentDir=%~dp0
set File=pixelized-lockscreen.exe
set Executable='%CurrentDir%%File%'
set command="try{Register-ScheduledTask -TaskName %TaskName% -Trigger (New-ScheduledTaskTrigger -AtLogon) -User '%CurrentUser%' -RunLevel Highest -Action (New-ScheduledTaskAction -Execute %Executable%) -Force; Write-Host 'RegisterTaskOnStartup: PixelizedLockscreen, done.'; }catch{ Write-Host 'RegisterTaskOnStartup: PixelizedLockscreen error:';Write-Host $_;}"

%PS% -Command %command%

:prompt
set /P OPEN=Open Task Scgheduler? Y/[N]
if /I "%OPEN%" neq "Y" goto end
start Taskschd.msc
:end

endlocal
