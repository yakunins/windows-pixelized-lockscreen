HandleIdleLocking(cfg) {
    if !cfg.enabled
        return
    if (cfg.idleTimeScreenshot < 1)
        return
    checkInterval := cfg.HasProp("idleCheck") ? cfg.idleCheck : 10
    _HandleIdleLocking_Start(cfg.idleTimeScreenshot, checkInterval)
}

_HandleIdleLocking_Start(idleTimeScreenshot, idleCheck) {
    threshold := (idleTimeScreenshot - idleCheck / 2) * 1000
    interval := idleCheck * 1000
    _HandleIdleLocking_Tick.idleTriggered := false
    _HandleIdleLocking_Tick.threshold := threshold
    _HandleIdleLocking_Tick.interval := interval
    SetTimer _HandleIdleLocking_Tick, interval
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
