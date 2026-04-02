HandleStartMenuLocking(cfg) {
    if !cfg.enabled
        return
    OnPowerClicked(_HandleStartMenuLocking_OnPower)
}

_HandleStartMenuLocking_OnPower(*) {
    Screenshot()
    SetLockScreen()
}
