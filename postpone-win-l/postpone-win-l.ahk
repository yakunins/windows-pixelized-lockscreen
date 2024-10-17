; adds extra delay between Win+L keypress and actual locking by intercepting keyboard activity
#Requires AutoHotkey v2.0
#SingleInstance Force

#include lib/MergeFileConfig.ahk
#include lib/PostponeWinLKeypress.ahk
#include lib/RemoveTrayTooltip.ahk
#include lib/UseBase64TrayIcon.ahk

config := {
    fileConfig: "config.json",
    postponePeriod: 100, ; if > 0, Win+L keypress to be intercepted and postponed on certain amount of milliseconds
    trayIcon: "postpone",
    trayTooltip: true,
    debug: false,
}
config := MergeFileConfig(config, config.debug) ; read local config, so it take pecedence

Run()
Run() {
    if (config.postponePeriod > 0)
        PostponeWinLKeypress(config.postponePeriod, OnWinL, config.debug)
    SetTrayIcon(config.trayIcon)
    if (config.trayTooltip == false)
        RemoveTrayTooltip()
}

; helper functions
if (config.debug)
    Hotkey "~LWin", OnWinDown, "On"

OnWinL() {
    if (config.debug)
        LogToFile("win+l pressed")
}
OnWinDown(key := 0) {
    if (config.debug)
        LogToFile("win key down")
}

SetTrayIcon(nameOrPath) {
    if (InStr(nameOrPath, ".")) {
        if FileExist(nameOrPath)
            TraySetIcon(nameOrPath)
    } else {
        UseBase64TrayIcon(config.trayIcon)
    }
}
LogToFile(str1, str2 := "") {
    if config.debug == 0
        return
    logFilePath := A_LineFile . "\..\postpone-win-l-log.txt"
    timestamp := " (" . FormatTime(, "hh:mm:ss") . "." A_MSec . ") "
    FileAppend str1 . timestamp . str2 . "`n", logFilePath
}