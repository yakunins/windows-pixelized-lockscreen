HandleKeypressLocking(cfg) {
    if !cfg.enabled
        return
    parsed := ParseHotkey(cfg.hotkey)
    hotkeyStr := parsed.modifiers . parsed.key
    delay := cfg.lockDelay
    Hotkey "$" . hotkeyStr, _HandleKeypressLocking_Handler.Bind(delay), "On"
}

_HandleKeypressLocking_Handler(delay, *) {
    Screenshot()
    SetLockScreen()
    LockWorkstation(delay)
}
