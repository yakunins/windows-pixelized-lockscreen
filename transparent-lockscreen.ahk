; generate pixelated screenshot and set it temporarily as lockscreen background image
#Requires AutoHotkey v2.0
#SingleInstance Force

#include lib/Log.ahk
#include lib/Ticks.ahk
#include lib/MergeFileConfig.ahk
#include lib/SetLockScreenImage.ahk ; SetLockScreenImage(), UnsetLockScreenImage()
#include lib/Screenshot.ahk ; ScreenshotToFile()
#include lib/LockSessionMonitor.ahk ; RegisterSessionMonitor(), UnregisterSessionMonitor()
#include lib/RemoveTrayTooltip.ahk
#include lib/UseBase64TrayIcon.ahk

config := {
    fileConfig: "config.json",
    pixelateSize: 10,
    blurSize: 2,
    screenshotFilename: "screenshot.png",
    removeScreenshot: {
        onWinKeyup: false,
        onUnlock: false,
        onExitApp: true,
    },
    unsetLockImage: {
        onUnlock: false,
        onExitApp: true,
    },
    registry: {
        path: 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP',
        item: 'LockScreenImagePath',
    },
    idlePeriod: 1000 * 60, ; 60 seconds = period of inactivity, screenshot to be set onto lockscreen after, 0 to disable
    trayIcon: "pixelation",
    debug: false,
}
config := MergeFileConfig(config, config.debug) ; read local config, so it take pecedence
config.screenshotPath := A_ScriptDir . "\" . config.screenshotFilename

state := {
    isLockImageSet: 0,
    isUnlocked: 1,
    isIdleCheckScheduled: 0,
    win: 0, ; state of win key (#)
}

Init()
Init() {
    ; test run
    Screenshot()
    SetLock()
    UnsetLock() ; 2ms

    ; supplemantary
    ScheduleIdleCheck()
    OnExit(ExitFn)
    RegisterSessionMonitor()

    ; key bindings
    Hotkey "~LWin", OnWinDown, "On"
    Hotkey "~RWin", OnWinDown, "On"
    Hotkey "~LWin up", OnWinUp, "On"
    Hotkey "~RWin up", OnWinUp, "On"

    ; fun
    RemoveTrayTooltip()
    SetTrayIcon(config.trayIcon)
}

; keypress handlers
OnWinDown(key := 0) {
    LogToFile("win key down")
    if state.win
        return
    state.win := 1
    Screenshot()
    if (config.unsetLockImage.onUnlock or state.isLockImageSet == 0)
        SetLock() ; could fail due to lock timing
}
OnWinUp(key := 0) {
    LogToFile("win key up")
    state.win := 0
    if config.removeScreenshot.onWinKeyup
        RemoveScreenshot()
}

; helper functions
Screenshot() {
    LogToFile("ScreenshotToFile()")
    ScreenshotToFile(config.screenshotPath, config.pixelateSize, config.blurSize, config.debug) ; ~33ms
}
SetLock() {
    LogToFile("SetLock()")
    SetLockScreenImage(config.screenshotPath, config.registry.path, config.registry.item, config.debug) ; ~3ms
    state.isLockImageSet := 1
}
UnsetLock() {
    LogToFile("UnsetLock()")
    UnsetLockScreenImage(config.registry.path, config.registry.item, config.debug) ; ~2ms
    state.isLockImageSet := 0
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
    if GetKeyState("LWin") or GetKeyState("RWin") {
        state.win := 1
    } else {
        state.win := 0
    }
    if config.unsetLockImage.onUnlock
        UnsetLock()
    if config.removeScreenshot.onUnlock
        RemoveScreenshot()
}
ScheduleIdleCheck(period := 10000) { ; default period is 10 seconds
    if (config.idlePeriod > 0) {
        if state.isIdleCheckScheduled
            return
        state.isIdleCheckScheduled := 1
        SetTimer IdleCheck, period * -1
    }
}
IdleCheck() {
    LogToFile("IdleCheck()")
    state.isIdleCheckScheduled := 0
    if A_TimeIdle > config.idlePeriod { ; is idle now
        SetLock()
        ScheduleIdleCheck(config.idlePeriod)
    } else {
        ScheduleIdleCheck()
    }
}
ExitFn(ExitReason, ExitCode) {
    LogToFile("ExitFn()")
    UnregisterSessionMonitor(ExitReason, ExitCode)
    if (ExitReason == "Close" or ExitReason == "Error")
        return
    ; Logoff, Shutdown, Menu, Exit, Reload, Single
    if config.unsetLockImage.onExitApp
        UnsetLock()
    if config.removeScreenshot.onExitApp
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
LogToFile(str1, str2 := "") {
    if config.debug == 0
        return
    logFilePath := A_LineFile . "\..\log.txt"
    timestamp := " (" . FormatTime(, "hh:mm:ss") . "." A_MSec . ") "
    FileAppend str1 . timestamp . str2 . "`n", logFilePath
}