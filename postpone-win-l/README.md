# Postpone Win+L Keypress

## How It Works
Intercepts `Win+L` keypress on driver level, Windows can't catch it immediatelly.  
After 100ms by default emulated `Win+L` keypress to be sent effectively locking the PC.  
Based on [AutoHotInterception](https://github.com/evilC/AutoHotInterception) and [The Interception](https://github.com/oblitum/Interception).

## Installation
1. Download [`postpone-win-l.exe`](postpone-win-l.exe), a compiled version (AHKv2-64) of the script
2. Download and run [`install.cmd`](install.cmd) to create `on-logon` scheduled task (`run as admin` might be required)
3. Download and run [`uninstall-interception-driver.cmd`](uninstall-interception-driver.cmd) to install keyboard interception driver (`rstart` might be required)

## Customization
Download and modyfy [`config.json`](config.json).

Enjoy!

