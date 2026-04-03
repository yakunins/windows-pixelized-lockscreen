#Requires AutoHotkey v2.0

#include DisableLockWorkstation.ahk
#include EnableLockWorkstation.ahk


HandleKeypressLocking(cfg) {
    if !cfg.enabled
        return
    parsed := ParseHotkey(cfg.hotkey)
    hotkeyStr := parsed.modifiers . parsed.key
    delay := cfg.lockDelay
    Hotkey "$" . hotkeyStr, _HandleKeypressLocking_Handler.Bind(delay), "On"
}

_HandleKeypressLocking_Handler(delay, *) {
    DisableLockWorkstation()
    Screenshot()
    SetLockScreen()
    EnableLockWorkstation()
    LockWorkstation(delay)
}
