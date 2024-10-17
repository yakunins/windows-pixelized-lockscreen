:: install Interception driver (restart required)
@echo off
setlocal EnableExtensions DisableDelayedExpansion

set PS=powershell.exe -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile

:: unblock (dlls are often blocked and will be blocked)
set UnblockDlls="try{Get-ChildItem -Path '%CurrentDir%\lib' -Recurse | Unblock-File; Write-Host 'Unblock AHI: done.'; }catch{ Write-Host 'Unblock AHI: error:';Write-Host $_;}"
%PS% -Command %UnblockDlls%

:: install Interception driver, see https://github.com/oblitum/Interception/releases
set InstallDriver="start-process '%CurrentDir%\lib\InterceptionDriver\command line installer\install-interception.exe' '/install'"
%PS% -Command %InstallDriver%

endlocal
