; Detects laptop lid close via RegisterPowerSettingNotification
; Captures screenshot before system locks/suspends on lid close

HandleLidCloseLocking(cfg) {
    if !cfg.enabled
        return

    ; GUID_LIDSWITCH_STATE_CHANGE {BA3E0F4D-B817-4094-A2D1-D56379E6A0F3}
    guid := Buffer(16)
    DllCall("ole32\CLSIDFromString", "str", "{BA3E0F4D-B817-4094-A2D1-D56379E6A0F3}", "ptr", guid)
    DllCall("RegisterPowerSettingNotification", "ptr", A_ScriptHwnd, "ptr", guid, "uint", 0)

    OnMessage(0x0218, _OnPowerBroadcast) ; WM_POWERBROADCAST
}

_OnPowerBroadcast(wParam, lParam, msg, hwnd) {
    if (wParam != 0x8013) ; PBT_POWERSETTINGCHANGE
        return

    ; POWERBROADCAST_SETTING struct:
    ;   GUID PowerSetting (16 bytes)
    ;   DWORD DataLength  (4 bytes, offset 16)
    ;   BYTE Data[]       (offset 20)
    lidState := NumGet(lParam, 20, "uint")

    ; lidState: 0 = lid closed, 1 = lid opened
    if (lidState == 0) {
        Screenshot()
        SetLockScreen()
    }
}
