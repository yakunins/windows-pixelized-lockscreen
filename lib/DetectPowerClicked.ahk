; Detects Power button click in Start Menu via ClickLogger listener

OnPowerClicked(callback) {
    _PowerDetect.callback := callback
    OnClickDetected(_OnPowerClickCheck)
}

_OnPowerClickCheck(autoId, elName, winClass, winExe) {
    if (autoId == "PowerButton")
        _PowerDetect.callback()
}

class _PowerDetect {
    static callback := ""
}
