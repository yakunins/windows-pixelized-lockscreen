# Postpone Win+L Keypress

## How It Works
Intercepts `Win+L` keypress on driver level, so Windows wouldn't catch it immediatelly.  
Then, after 100ms, emulated `Win+L` keypress to be sent, locking the PC effectively.  
Based on [AutoHotInterception](https://github.com/evilC/AutoHotInterception) and [Interception](https://github.com/oblitum/Interception).

## Installation
1. Download [`postpone-win-l.exe`](postpone-win-l.exe), a compiled version (AHKv2-64) of the script
2. Download and run [`install.cmd`](install.cmd) to create `on-logon` scheduled task (`run as admin` may be required)
3. Download and run [`uninstall-interception-driver.cmd`](uninstall-interception-driver.cmd) to install keyboard interception driver (`rstart` may be required)
4. (optional) Download and modyfy [`config.json`](config.json).

Enjoy!

