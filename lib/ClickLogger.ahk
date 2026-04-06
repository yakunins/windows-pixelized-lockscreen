; Logs every mouse click with position, window info, and UI Automation element info
; Also supports click listeners that get notified with click details

StartClickLogger() {
    ; Create and keep UIA COM object alive
    _ClickLog._uiaObj := ComObject("{ff48dba4-60ef-4201-aa87-54103eef594e}", "{30cbe57d-d9d0-452a-ab13-7ac5ac4825ee}")
    _ClickLog.uia := ComObjValue(_ClickLog._uiaObj)
    _ClickLog.listeners := []
    ; Register low-level mouse hook via hotkeys
    Hotkey "~LButton", _OnClickLog, "On"
    Hotkey "~RButton", _OnClickLog, "On"
    Hotkey "~MButton", _OnClickLog, "On"
}

OnClickDetected(callback) {
    _ClickLog.listeners.Push(callback)
}

_OnClickLog(key) {
    CoordMode "Mouse", "Screen"
    MouseGetPos &mx, &my, &winHwnd, &control

    ; Window info
    try {
        winTitle := WinGetTitle(winHwnd)
        winClass := WinGetClass(winHwnd)
        winExe := WinGetProcessName(winHwnd)
    } catch {
        winTitle := ""
        winClass := ""
        winExe := ""
    }

    ; UIA element info
    elName := ""
    elAutoId := ""
    elType := ""
    try {
        uia := _ClickLog.uia
        if uia {
            ; IUIAutomation::ElementFromPoint (vtable 7)
            ; POINT is two int32s packed into one int64
            point := (my << 32) | (mx & 0xFFFFFFFF)
            hr := ComCall(7, uia, "int64", point, "ptr*", &el := 0)
            if (hr == 0 && el) {
                elName := _ClickLog_GetProp(el, 30005)    ; UIA_NamePropertyId
                elAutoId := _ClickLog_GetProp(el, 30011)  ; UIA_AutomationIdPropertyId
                elType := _ClickLog_GetPropInt(el, 30003)  ; UIA_ControlTypePropertyId
                ObjRelease(el)
            }
        }
    }

    ; Format log line
    btn := StrReplace(StrReplace(key, "~", ""), " up", "")
    line := btn . " (" . mx . "," . my . ")"
        . " win:`"" . winTitle . "`" class:" . winClass . " exe:" . winExe
        . " el:`"" . elName . "`" autoId:" . elAutoId . " type:" . elType
        . (control ? " ctrl:" . control : "")
    ; Notify listeners (always, regardless of logging setting)
    for listener in _ClickLog.listeners
        listener(elAutoId, elName, winClass, winExe)

    ; Log to file only when debugClicks is enabled
    if !config.debugClicks
        return
    logDir := A_ScriptDir . "\logs"
    if !DirExist(logDir)
        DirCreate(logDir)
    logFilePath := logDir . "\log.txt"
    timestamp := " (" . FormatTime(, "hh:mm:ss") . "." A_MSec . ") "
    FileAppend "Click" . timestamp . line . "`n", logFilePath
}

; Get string property from UIA element
_ClickLog_GetProp(el, propId) {
    ; IUIAutomationElement::GetCurrentPropertyValue (vtable 10)
    var := Buffer(16, 0)
    hr := ComCall(10, el, "int", propId, "ptr", var)
    if (hr != 0)
        return ""
    vt := NumGet(var, 0, "ushort")
    if (vt == 8) { ; VT_BSTR
        bstr := NumGet(var, 8, "ptr")
        if bstr {
            result := StrGet(bstr)
            DllCall("oleaut32\SysFreeString", "ptr", bstr)
            return result
        }
    }
    return ""
}

; Get int property from UIA element
_ClickLog_GetPropInt(el, propId) {
    var := Buffer(16, 0)
    hr := ComCall(10, el, "int", propId, "ptr", var)
    if (hr != 0)
        return ""
    vt := NumGet(var, 0, "ushort")
    if (vt == 3) ; VT_I4
        return NumGet(var, 8, "int")
    return ""
}

class _ClickLog {
    static _uiaObj := ""
    static uia := 0
}
