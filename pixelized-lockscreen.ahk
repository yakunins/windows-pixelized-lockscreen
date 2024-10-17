; generates pixelized screenshot on Win keypress, and set it as lockscreen background (temporarily, until reset or logoff)
#Requires AutoHotkey v2.0
#SingleInstance Force

#include lib/MergeFileConfig.ahk
#include lib/Screenshot.ahk ; ScreenshotToFile()
#include lib/SetLockScreenImage.ahk ; SetLockScreenImage(), UnsetLockScreenImage()
#include lib/LockSessionMonitor.ahk ; RegisterSessionMonitor(), UnregisterSessionMonitor()
#include lib/RemoveTrayTooltip.ahk
#include lib/UseBase64TrayIcon.ahk
#include lib/Log.ahk
#include lib/Ticks.ahk

config := {
    fileConfig: "config.json",
    pixelateSize: 10,
    blurSize: 2, ; effectively screenshot scale, e.g. 1920×1080 to produce 960×540 screenshot
    idlePeriod: 1000 * 60, ; period of inactivity, after which screenshot to be set as lockscreen image, 0 to disable
    screenshotFilename: "screenshot.png",
    removeScreenshot: {
        onWinKeyup: false,
        onUnlock: false,
        onExitApp: true,
    },
    unsetLockImage: {
        onUnlock: false,
        onExitApp: true, ; including on reset, logoff, shut down
    },
    registry: {
        path: 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP',
        item: 'LockScreenImagePath',
    },
    trayIcon: "screenshotlock",
    trayTooltip: true,
    debug: false,
}
config := MergeFileConfig(config, config.debug) ; read local config, so it take pecedence
config.screenshotPath := A_ScriptDir . "\" . config.screenshotFilename

state := {
    isLockImageSet: 0,
    isUnlocked: 1,
    isIdle: 0,
    win: 0, ; state of win key (#)
}

Init()
Init() {
    ; test run start
    Screenshot()
    SetLockScreen()
    UnsetLockScreen()
    ; test run end

    if (config.idlePeriod > 0)
        IdleCheck()

    OnExit(ExitFn)
    RegisterSessionMonitor()

    ; key bindings
    Hotkey "~LWin", OnWinDown, "On"
    Hotkey "~RWin", OnWinDown, "On"
    Hotkey "~LWin up", OnWinUp, "On"
    Hotkey "~RWin up", OnWinUp, "On"

    ; fun
    SetTrayIcon(config.trayIcon)
    if (config.trayTooltip == false)
        RemoveTrayTooltip()
}

; keypress handlers
OnWinDown(key := 0) {
    LogToFile("Win key down")
    if state.win
        return
    state.win := 1
    Screenshot()
    SetLockScreen() ; could fail due to lock timing
}
OnWinUp(key := 0) {
    LogToFile("Win key up")
    state.win := 0
    if config.removeScreenshot.onWinKeyup
        RemoveScreenshot()
}

; helper functions
Screenshot() {
    LogToFile("Screenshot()")
    ScreenshotToFile(config.screenshotPath, config.pixelateSize, config.blurSize, config.debug) ; ~33ms
}
SetLockScreen() {
    LogToFile("SetLockScreen()")
    if !state.isLockImageSet {
        SetLockScreenImage(config.screenshotPath, config.registry.path, config.registry.item, config.debug) ; ~3ms
        state.isLockImageSet := 1
    }
}
UnsetLockScreen() {
    LogToFile("UnsetLockScreen()")
    if state.isLockImageSet {
        UnsetLockScreenImage(config.registry.path, config.registry.item, config.debug) ; ~2ms
        state.isLockImageSet := 0
    }
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
        UnsetLockScreen()
    if config.removeScreenshot.onUnlock
        RemoveScreenshot()
}
IdleCheck() {
    if A_TimeIdle > config.idlePeriod {
        SetTimer IdleCheck, config.idlePeriod * -1 ; if idle, schedule next check for (not) idle after minute
        if !state.isIdle {
            state.isIdle := 1
            Screenshot() ; this may abort sleep timer as of Screenshot() uses disk access inside
            SetLockScreen()
        }
    } else {
        SetTimer IdleCheck, 10 * 1000 * -1 ; if schedule check for idle after 10 seconds
        state.isIdle := 0
    }
}
ExitFn(ExitReason, ExitCode) {
    LogToFile("ExitFn()")
    UnregisterSessionMonitor(ExitReason, ExitCode)
    if (ExitReason == "Close" or ExitReason == "Error")
        return
    ; Logoff, Shutdown, Menu, Exit, Reload, Single
    if config.unsetLockImage.onExitApp
        UnsetLockScreen()
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