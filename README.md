# Lockscreen with Pixelized Screenshot

<img src="images/pixelized-lockscreen-how-it-works.gif" width="768" alt="pixelized lockscreen background: how it works" />

## How It Works
When you press Win+L, a pixelated/blurred screenshot is taken and set as your lock screen background, then the workstation is locked.
The same screenshot capture happens when you press the Windows key alone, or after a period of inactivity.
This helps you stay focused and maintain an unobtrusive work environment, see [Hund's recommendations](https://web.archive.org/web/20231004142509/https://hund.tty1.se/2018/09/04/use-a-pixelated-version-of-your-desktop-as-your-lockscreen-with-i3lock.html).  

## Installation
1. Download [`pixelized-lockscreen.exe`](pixelized-lockscreen.exe), a compiled version (AHKv2-64) of the script
2. Download and run [`install.cmd`](install.cmd) to run it on startup as scheduled task (`run as admin` might be required)

The installer disables the native Win+L shortcut via registry, so the app can handle it programmatically (screenshot, set lock screen, then lock). Running [`uninstall.cmd`](uninstall.cmd) re-enables native Win+L.

## Customization
Download and modify [`config.json`](config.json).  

To reduce screenshot size, provide `blurSize` with a greater value: effectively, blur size means screenshot scale, e.g. when screen resolution is 1920x1080, `blurSize=2` produces a 960x540 screenshot.  

Enjoy!
