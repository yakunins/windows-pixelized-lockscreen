; Monitors paired Bluetooth devices and captures screenshot when one disconnects
; Works with Windows Dynamic Lock — we set the lock screen image preemptively,
; then Dynamic Lock handles the actual lock ~30s after device goes out of range
;
; Uses BluetoothFindFirstDevice / BluetoothGetDeviceInfo to poll paired devices

HandleBluetoothDynamicLocking(cfg) {
    if !cfg.enabled
        return
    checkInterval := cfg.HasProp("checkInterval") ? cfg.checkInterval : 5
    _BtDetect.checkInterval := checkInterval * 1000
    _BtDetect.connectedDevices := _BtGetConnectedDevices()
    SetTimer _BtPollDevices, _BtDetect.checkInterval
}

_BtPollDevices() {
    current := _BtGetConnectedDevices()
    prev := _BtDetect.connectedDevices

    ; Check if any previously connected device is now gone
    lost := false
    for addr, name in prev {
        if !current.Has(addr) {
            lost := true
            break
        }
    }

    _BtDetect.connectedDevices := current

    if lost {
        Screenshot()
        SetLockScreen()
    }
}

; Returns a Map of connected paired Bluetooth devices: address => name
_BtGetConnectedDevices() {
    devices := Map()

    ; BLUETOOTH_DEVICE_SEARCH_PARAMS struct (48 bytes on x64)
    ; dwSize (4) + fReturnAuthenticated (4) + fReturnRemembered (4) + fReturnUnknown (4)
    ; + fReturnConnected (4) + fIssueInquiry (4) + cTimeoutMultiplier (4) + padding (4)
    ; + hRadio (8)
    searchParams := Buffer(48, 0)
    NumPut("uint", 48, searchParams, 0)             ; dwSize
    NumPut("int", 1, searchParams, 4)                ; fReturnAuthenticated (paired)
    NumPut("int", 0, searchParams, 8)                ; fReturnRemembered
    NumPut("int", 0, searchParams, 12)               ; fReturnUnknown
    NumPut("int", 1, searchParams, 16)               ; fReturnConnected
    NumPut("int", 0, searchParams, 20)               ; fIssueInquiry (don't scan, just check)
    NumPut("uint", 0, searchParams, 24)              ; cTimeoutMultiplier

    ; BLUETOOTH_DEVICE_INFO struct (560 bytes)
    ; dwSize (4) + Address (8) + ulClassofDevice (4) + fConnected (4) + fRemembered (4)
    ; + fAuthenticated (4) + stLastSeen (16) + stLastUsed (16) + szName (496 = 248 wchars)
    deviceInfo := Buffer(560, 0)
    NumPut("uint", 560, deviceInfo, 0)               ; dwSize

    hFind := DllCall("bthprops.cpl\BluetoothFindFirstDevice", "ptr", searchParams, "ptr", deviceInfo, "ptr")

    if !hFind
        return devices

    loop {
        fConnected := NumGet(deviceInfo, 16, "int")
        if fConnected {
            addr := NumGet(deviceInfo, 4, "int64")
            name := StrGet(deviceInfo.Ptr + 64, 248)
            devices[addr] := name
        }

        ; Reset dwSize for next call
        NumPut("uint", 560, deviceInfo, 0)
        if !DllCall("bthprops.cpl\BluetoothFindNextDevice", "ptr", hFind, "ptr", deviceInfo)
            break
    }

    DllCall("bthprops.cpl\BluetoothFindDeviceClose", "ptr", hFind)
    return devices
}

class _BtDetect {
    static checkInterval := 5000
    static connectedDevices := Map()
}
