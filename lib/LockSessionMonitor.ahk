; © wilkster https://www.autohotkey.com/boards/viewtopic.php?p=542126#p542126

RegisterSessionMonitor() {
    Static WTS_CURRENT_SERVER := 0
    Static NOTIFY_FOR_ALL_SESSIONS := 1

    if !(DllCall("wtsapi32.dll\WTSRegisterSessionNotificationEx", "Ptr", WTS_CURRENT_SERVER, "Ptr", A_ScriptHwnd, "UInt", NOTIFY_FOR_ALL_SESSIONS))
        return false
    OnMessage(0x02B1, WM_WTSSESSION_CHANGE)
    return true
}

UnregisterSessionMonitor(ExitReason, ExitCode) {
    Static WTS_CURRENT_SERVER := 0
    Static NOTIFY_FOR_ALL_SESSIONS := 1
    try {
        OnMessage(0x02B1, "")
        if !(DllCall("wtsapi32.dll\WTSUnRegisterSessionNotificationEx", "Ptr", WTS_CURRENT_SERVER, "Ptr", A_ScriptHwnd))
            return false
    }
    return true
}

; http://msdn.com/library/aa383828(vs.85,en-us)
WM_WTSSESSION_CHANGE(wParam, lParam, msg, hwnd) {
    Static WTS_SESSION_LOCK := 0x7
    Static WTS_SESSION_UNLOCK := 0x8

    switch wParam {
        case WTS_SESSION_LOCK:
            state.isUnlocked := false
            OnSessionLock()
            OutputDebug("WTS_SESSION_LOCK")
        case WTS_SESSION_UNLOCK:
            state.isUnlocked := true
            OnSessionUnlock()
            OutputDebug("WTS_SESSION_UNLOCK")
        default:
    }
}