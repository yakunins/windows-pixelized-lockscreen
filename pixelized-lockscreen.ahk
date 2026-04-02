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
#include lib/LockSessionMonitor.ahk ; RegisterSessionMonitor(), UnregisterSessionMonitor()
#include lib/RemoveTrayTooltip.ahk
#include lib/UseBase64TrayIcon.ahk
#include lib/Log.ahk
#include lib/Ticks.ahk

config := {
    fileConfig: "config.json",
    handleKeypressLocking: {
        enabled: true,
        hotkey: "Win+L",
        lockDelay: 50,
    },
    handleIdleLocking: {
        enabled: true,
        idlePeriod: 1000 * 60,
    },
    handleStartMenuLocking: {
        enabled: false,
    },
    screenshot: {
        pixelateSize: 10,
        blurSize: 2,
        filename: "screenshot.png",
        removeOnUnlock: false,
        removeOnExitApp: true,
    },
    lockScreen: {
        registryPath: 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP',
        registryItem: 'LockScreenImagePath',
        defaultImagePath: false,
        unsetOnUnlock: false,
        unsetOnExitApp: true,
    },
    trayIcon: "screenshotlock",
    trayTooltip: true,
    debug: false,
}
config := MergeFileConfig(config, config.debug)
config.screenshotPath := A_ScriptDir . "\" . config.screenshot.filename
config.resolvedDefaultImagePath := config.lockScreen.defaultImagePath != 0
    ? GetFullPath(config.lockScreen.defaultImagePath) : 0

state := {
    isLockScreenSet: 0,
    isIdle: 0,
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

    ; locking handlers
    HandleKeypressLocking(config.handleKeypressLocking)

    if config.handleIdleLocking.enabled
        IdleCheck()

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
OnSessionLock() {
    LogToFile("OnSessionLock()")
}
OnSessionUnlock() {
    LogToFile("OnSessionUnlock()")
    if config.lockScreen.unsetOnUnlock
        UnsetLockScreen()
    if config.screenshot.removeOnUnlock
        RemoveScreenshot()
    if (!config.lockScreen.unsetOnUnlock and !config.screenshot.removeOnUnlock)
        SetLockScreen(true)
}
IdleCheck() {
    period := config.handleIdleLocking.idlePeriod
    if (period < 100)
        return
    if A_TimeIdle < period {
        state.isIdle := 0
        SetTimer IdleCheck, period * -0.2
    } else {
        SetTimer IdleCheck, period * -1
        if !state.isIdle {
            state.isIdle := 1
            Screenshot()
            SetLockScreen()
        }
    }
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
