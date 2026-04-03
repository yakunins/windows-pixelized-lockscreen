# Lockscreen with Pixelized Screenshot

<img src="images/pixelized-lockscreen-how-it-works.gif" width="768" alt="pixelized lockscreen background: how it works" />

## How It Works
When you press Win+L, a pixelated/blurred screenshot is taken and set as your lock screen background, then the workstation is locked.
The same screenshot capture happens after a period of inactivity, when clicking the Power button in Start Menu, on laptop lid close, or when a paired Bluetooth device goes out of range (Dynamic Lock).
This helps you stay focused and maintain an unobtrusive work environment, see [Hund's recommendations](https://hunden.linuxkompis.se/2018/09/04/use-a-pixelated-version-of-your-desktop-as-your-lockscreen-with-i3lock.html).  

## Installation
1. Download the [latest release](https://github.com/yakunins/windows-pixelized-lockscreen/releases/latest) and extract the zip
2. Run `install.cmd` to register as a startup scheduled task and disable native Win+L (`run as admin` might be required)

The installer disables the native Win+L shortcut via registry, so the app can handle it programmatically (screenshot, set lock screen, then lock). Running `uninstall.cmd` re-enables native Win+L and removes the scheduled task.

## Customization
Modify [`config.json`](config.json) to enable/disable locking handlers and adjust settings.

To reduce screenshot size, provide `blurSize` with a greater value: effectively, blur size means screenshot scale, e.g. when screen resolution is 1920x1080, `blurSize=2` produces a 960x540 screenshot.  

Enjoy!
