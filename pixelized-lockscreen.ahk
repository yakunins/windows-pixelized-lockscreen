; generates pixelized screenshot and sets it as lockscreen background
; (c) Sergey Yakunin and others, see files in lib folder

#Requires AutoHotkey v2.0
#SingleInstance Force

#include lib/MergeFileConfig.ahk
#include lib/ParseHotkey.ahk
#include lib/Screenshot.ahk ; ScreenshotToFile()
#include lib/SetLockScreenImage.ahk ; SetLockScreenImage(), UnsetLockScreenImage()
#include lib/LockWorkstation.ahk ; LockWorkstation()
#include lib/HandleKeypressLocking.ahk ; HandleKeypressLocking()
#include lib/HandleIdleLocking.ahk ; HandleIdleLocking()
#include lib/DetectPowerClicked.ahk ; OnPowerClicked()
#include lib/HandleStartMenuLocking.ahk ; HandleStartMenuLocking()
#include lib/HandleLidCloseLocking.ahk ; HandleLidCloseLocking()
#include lib/HandleBluetoothDynamicLocking.ahk ; HandleBluetoothDynamicLocking()
#include lib/HandleCtrlAltDelLocking.ahk ; HandleCtrlAltDelLocking() — no-op, see comment
#include lib/HandleSessionEvents.ahk ; HandleSessionEvents()
#include lib/SessionMonitor.ahk ; RegisterSessionMonitor(), UnregisterSessionMonitor()
#include lib/ClickLogger.ahk ; StartClickLogger()
#include lib/RemoveTrayTooltip.ahk
#include lib/UseBase64TrayIcon.ahk

config := {
    version: "2.0",
    fileConfig: "config.json",
    handleKeypressLocking: {
        enabled: true,
        hotkey: "Win+L",
        lockDelay: 50,
    },
    handleIdleLocking: {
        enabled: true,
        idleTimeScreenshot: 30,
        idleCheck: 10,
    },
    handleStartMenuLocking: {
        enabled: false,
    },
    handleLidCloseLocking: {
        enabled: false,
    },
    handleBluetoothDynamicLocking: {
        enabled: false,
        checkInterval: 5, ; seconds between Bluetooth device polls
    },
    handleCtrlAltDelLocking: {
        enabled: false,
    },
    handleSessionEvents: {
        unsetLockScreenOnUnlock: false,
        removeScreenshotOnUnlock: false,
    },
    screenshot: {
        pixelateSize: 10,
        blurSize: 2,
        filename: "screenshot.png",
        removeOnExitApp: true,
    },
    lockScreen: {
        registryPath: 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP',
        registryItem: 'LockScreenImagePath',
        defaultImagePath: false,
        unsetOnExitApp: true,
    },
    trayIcon: "screenshotlock",
    trayTooltip: true,
    debug: false,
    debugClicks: false,
}
config := MergeFileConfig(config, config.debug)
config.screenshotPath := A_ScriptDir . "\" . config.screenshot.filename
config.resolvedDefaultImagePath := config.lockScreen.defaultImagePath != 0
    ? GetFullPath(config.lockScreen.defaultImagePath) : 0

state := {
    isLockScreenSet: 0,
}

Init()
Init() {
    ; test run
    Screenshot()
    SetLockScreen()
    UnsetLockScreen()
    RemoveScreenshot()

    RegisterSessionMonitor()
    OnExit(ExitFn)

    ; click logger (must start before handlers that use it)
    if (config.debugClicks or config.handleStartMenuLocking.enabled)
        StartClickLogger()

    ; locking handlers
    HandleKeypressLocking(config.handleKeypressLocking)
    HandleIdleLocking(config.handleIdleLocking)
    HandleStartMenuLocking(config.handleStartMenuLocking)
    HandleLidCloseLocking(config.handleLidCloseLocking)
    HandleBluetoothDynamicLocking(config.handleBluetoothDynamicLocking)
    HandleCtrlAltDelLocking(config.handleCtrlAltDelLocking)
    HandleSessionEvents(config.handleSessionEvents)

    ; tray
    SetTrayIcon(config.trayIcon)
    if (config.trayTooltip == false)
        RemoveTrayTooltip()
}

Screenshot() {
    LogToFile("Screenshot()")
    ScreenshotToFile(config.screenshotPath, config.screenshot.pixelateSize, config.screenshot.blurSize, config.debug)
}
SetLockScreen(force := false) {
    LogToFile("SetLockScreen()")
    if !state.isLockScreenSet or force {
        SetLockScreenImage(config.screenshotPath, config.lockScreen.registryPath, config.lockScreen.registryItem, config.debug)
        state.isLockScreenSet := 1
    }
}
UnsetLockScreen(force := false) {
    LogToFile("UnsetLockScreen()")
    if (state.isLockScreenSet and !force)
        return
    state.isLockScreenSet := 0
    if config.resolvedDefaultImagePath != 0 and FileExist(config.resolvedDefaultImagePath) {
        SetLockScreenImage(config.resolvedDefaultImagePath, config.lockScreen.registryPath, config.lockScreen.registryItem, config.debug)
        return
    }
    UnsetLockScreenImage(config.lockScreen.registryPath, config.lockScreen.registryItem, config.debug)
}
RemoveScreenshot() {
    LogToFile("RemoveScreenshot()")
    DeleteFile(config.screenshotPath)
}
ExitFn(ExitReason, ExitCode) {
    LogToFile("ExitFn()")
    UnregisterSessionMonitor(ExitReason, ExitCode)
    if (ExitReason == "Close" or ExitReason == "Error")
        return
    if config.lockScreen.unsetOnExitApp
        UnsetLockScreen(true)
    if config.screenshot.removeOnExitApp
        RemoveScreenshot()
}
SetTrayIcon(nameOrPath) {
    if (InStr(nameOrPath, ".")) {
        if FileExist(nameOrPath)
            TraySetIcon(nameOrPath)
    } else {
        UseBase64TrayIcon(config.trayIcon)
    }
}
DeleteFile(path) {
    if (FileExist(path))
        try {
            FileDelete(path)
            return 1
        } catch Error as e {
            if config.debug
                MsgBox "Error: FileDelete(" . path . ")"
            return 0
        }
}
GetFullPath(path) {
    cc := DllCall("GetFullPathNameW", "str", path, "uint", 0, "ptr", 0, "ptr", 0, "uint")
    buf := Buffer(cc * 2)
    DllCall("GetFullPathNameW", "str", path, "uint", cc, "ptr", buf, "ptr", 0, "uint")
    return StrGet(buf)
}
LogToFile(str1, str2 := "") {
    if config.debug == 0
        return
    logFilePath := A_LineFile . "\..\log.txt"
    timestamp := " (" . FormatTime(, "hh:mm:ss") . "." A_MSec . ") "
    FileAppend str1 . timestamp . str2 . "`n", logFilePath
}
