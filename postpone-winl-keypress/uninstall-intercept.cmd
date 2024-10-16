:: uninstall Interception driver (restart required)
@echo off
setlocal EnableExtensions DisableDelayedExpansion
set PS=powershell.exe -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile
set UninstallDriver="start-process '%CurrentDir%\lib\InterceptionDriver\command line installer\install-interception.exe' '/uninstall'"
%PS% -Command %UninstallDriver%
endlocal
