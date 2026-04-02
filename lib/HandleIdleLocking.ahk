HandleIdleLocking(cfg) {
    if !cfg.enabled
        return
    screenshotAfter := _ParseDuration(cfg.screenshotAfter)
    if (screenshotAfter < 1000)
        return
    checkInterval := cfg.HasProp("idleCheckInterval") ? _ParseDuration(cfg.idleCheckInterval) : 10000
    _HandleIdleLocking_Start(screenshotAfter, checkInterval)
}

; Parses duration value: "20s" → 20000ms, "500ms" → 500ms, 20 → 20 (ms)
_ParseDuration(val) {
    if IsNumber(val)
        return val
    val := Trim(val)
    if (SubStr(val, -1) == "ms")
        return Number(SubStr(val, 1, -2))
    if (SubStr(val, -1) == "s")
        return Number(SubStr(val, 1, -1)) * 1000
    return Number(val)
}

_HandleIdleLocking_Start(screenshotAfterMs, checkIntervalMs) {
    threshold := screenshotAfterMs - checkIntervalMs / 2
    _HandleIdleLocking_Tick.idleTriggered := false
    _HandleIdleLocking_Tick.threshold := threshold
    SetTimer _HandleIdleLocking_Tick, checkIntervalMs
}

_HandleIdleLocking_Tick() {
    if A_TimeIdle > _HandleIdleLocking_Tick.threshold {
        if !_HandleIdleLocking_Tick.idleTriggered {
            _HandleIdleLocking_Tick.idleTriggered := true
            Screenshot()
            SetLockScreen()
        }
    } else {
        _HandleIdleLocking_Tick.idleTriggered := false
    }
}
