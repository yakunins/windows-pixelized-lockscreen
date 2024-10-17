; generates pixelized screenshot on Win keypress
; set it as lockscreen background (temporarily, until reset or logoff)
; (c) Sergey Yakunin and others, see files in lib folder

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
    blurSize: 2, ; effectively screenshot scale, e.g. 1920*1080 to produce 960*540 screenshot
    idlePeriod: 1000 * 60, ; period of inactivity, after which screenshot to be set as lockscreen image, 0 to disable
    screenshotFilename: "screenshot.png",
    removeScreenshot: {
        onWinKeyup: false,
        onUnlock: false,
        onExitApp: true,
    },
    unsetLockImage: {
        imagePath: false, ; if no Win+L was used, use this image as a default lockscreen background
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
config.defaultImagePath := config.unsetLockImage.imagePath != 0 ? GetFullPath(config.unsetLockImage.imagePath) : 0

state := {
    isLockScreenSet: 0,
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
    RemoveScreenshot()
    ; test run end

    RegisterSessionMonitor()
    OnExit(ExitFn)
    IdleCheck()

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
SetLockScreen(force := false) {
    LogToFile("SetLockScreen()")
    if !state.isLockScreenSet or force {
        SetLockScreenImage(config.screenshotPath, config.registry.path, config.registry.item, config.debug) ; ~3ms
        state.isLockScreenSet := 1
    }
}
UnsetLockScreen(force := false) {
    LogToFile("UnsetLockScreen()")
    if (state.isLockScreenSet and !force)
        return
    state.isLockScreenSet := 0
    if config.defaultImagePath != 0 and FileExist(config.defaultImagePath) {
        LogToFile("FileExist()!" config.defaultImagePath)
        SetLockScreenImage(config.defaultImagePath, config.registry.path, config.registry.item, config.debug) ; ~3ms
        return
    }
    UnsetLockScreenImage(config.registry.path, config.registry.item, config.debug) ; ~2ms
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
    if (!config.unsetLockImage.onUnlock and !config.removeScreenshot.onUnlock)
        SetLockScreen(true)
}
IdleCheck() {
    if (config.idlePeriod < 100) ; less than 100 ms
        return
    if A_TimeIdle < config.idlePeriod {
        ; not idle yet
        state.isIdle := 0
        SetTimer IdleCheck, config.idlePeriod * -0.2 ; schedule next check after 12 seconds (default)
    } else {
        ; already idle
        SetTimer IdleCheck, config.idlePeriod * -1  ; schedule next check after 60 seconds (default)
        if !state.isIdle {
            state.isIdle := 1
            Screenshot() ; this may abort sleep timer as of Screenshot() internally writes on disk
            SetLockScreen()
        }
    }
}
ExitFn(ExitReason, ExitCode) {
    LogToFile("ExitFn()")
    UnregisterSessionMonitor(ExitReason, ExitCode)
    if (ExitReason == "Close" or ExitReason == "Error")
        return
    ; Logoff, Shutdown, Menu, Exit, Reload, Single
    if config.unsetLockImage.onExitApp
        UnsetLockScreen(true)
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
GetFullPath(path) {
    ; (c) lexicos
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