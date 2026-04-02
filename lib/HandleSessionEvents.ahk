HandleSessionEvents(cfg) {
    _HandleSessionEvents.cfg := cfg
}

OnSessionLock() {
    LogToFile("OnSessionLock()")
}

OnSessionUnlock() {
    LogToFile("OnSessionUnlock()")
    cfg := _HandleSessionEvents.cfg
    if cfg.unsetLockScreenOnUnlock
        UnsetLockScreen()
    if cfg.removeScreenshotOnUnlock
        RemoveScreenshot()
    if (!cfg.unsetLockScreenOnUnlock and !cfg.removeScreenshotOnUnlock)
        SetLockScreen(true)
}

class _HandleSessionEvents {
    static cfg := {}
}
