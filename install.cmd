:: creates at-startup Scheduled Task and disables native Win+L
@echo off
setlocal EnableExtensions DisableDelayedExpansion

:: Disable native Win+L (app handles it programmatically)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableLockWorkstation /t REG_DWORD /d 1 /f
echo Win+L disabled (handled by app).

set PS=powershell.exe -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile
set TaskName='PixelizedLockscreen'
set CurrentUser=%USERDOMAIN%\%USERNAME%
set CurrentDir=%~dp0
set File=pixelized-lockscreen.exe
set Executable='%CurrentDir%%File%'

set CreateTask="try{Register-ScheduledTask -TaskName %TaskName% -Trigger (New-ScheduledTaskTrigger -AtLogon) -User '%CurrentUser%' -RunLevel Highest -Action (New-ScheduledTaskAction -Execute %Executable%) -Force; Write-Host 'RegisterTaskOnStartup: PixelizedLockscreen, done.'; }catch{ Write-Host 'RegisterTaskOnStartup: PixelizedLockscreen error:';Write-Host $_;}"
%PS% -Command %CreateTask%

:prompt
set /P OPEN=Open Task Scgheduler? Y/[N]
if /I "%OPEN%" neq "Y" goto end
start Taskschd.msc
:end

endlocal
