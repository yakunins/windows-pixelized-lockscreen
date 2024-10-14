; keys state manager for AutoHotInterception, see https://github.com/evilC/AutoHotInterception

#Requires AutoHotkey v2.0
#SingleInstance Force

#include AutoHotInterception.ahk

class Keys {
    static AHI := AutoHotInterception()
    static pressed := [] ; keys currently pressed, format "deviceid:scancode"
    static faked := [] ; emulated keypresses
    static keyboards := this.GetKeyboards() ; list of keyboards
    static mice := this.GetMice() ; list of mice
    static activeKeyboard := 0 ; last active keyboard
    static div := '-'

    static Down(scancode, deviceid) { ; real
        this.activeKeyboard := deviceid
        keyname := deviceid this.div scancode
        if !this.IsPressed(scancode, deviceid)
            this.pressed.push(keyname)
    }
    static Up(scancode, deviceid) {
        this.activeKeyboard := deviceid
        keyname := deviceid this.div scancode
        idx := FindIndex(this.pressed, keyname)
        if (idx > 0)
            this.pressed.RemoveAt(idx)
    }
    static FakeDown(scancode, deviceid := this.activeKeyboard) {
        keyname := deviceid this.div scancode
        this.AHI.SendKeyEvent(deviceid, scancode, 1)
        if !this.IsFaked(scancode, deviceid)
            this.faked.push(keyname)
    }
    static FakeUp(scancode, deviceid := this.activeKeyboard) {
        keyname := deviceid this.div scancode
        this.AHI.SendKeyEvent(deviceid, scancode, 0)
        idx := FindIndex(this.faked, keyname)
        if (idx > 0)
            this.faked.RemoveAt(idx)
    }
    static IsPressed(scancode, deviceid := this.activeKeyboard) {
        keyname := deviceid this.div scancode
        if FindIndex(this.pressed, keyname) != 0
            return 1
        return 0
    }
    static IsFaked(scancode, deviceid := this.activeKeyboard) {
        keyname := deviceid this.div scancode
        if FindIndex(this.faked, keyname) != 0
            return 1
        return 0
    }
    static PressedCount(deviceid := this.activeKeyboard) {
        substr := deviceid this.div
        return Count(this.pressed, substr)
    }
    static FakedCount(deviceid := this.activeKeyboard) {
        substr := deviceid this.div
        return Count(this.faked, substr)
    }
    static GetKeyboards() {
        return this.GetDevices(0)
    }
    static GetMice() {
        return this.GetDevices(1)
    }
    static GetDevices(isMouse) {
        devices := this.AHI.GetDeviceList() ; format: {'1': {'id': 1, 'IsMouse': 0, ...}}
        result := Map()
        for id, val in devices {
            if val.IsMouse == isMouse {
                val.DeleteProp("IsMouse")
                val.DeleteProp("ID")
                val.DeleteProp("PID")
                val.DeleteProp("VID")
                result[id] := val
            }
        }
        return result
    }
}

FindIndex(arr, val) {
    Loop arr.Length {
        if (arr[A_Index] == val or InStr(arr[A_Index], val))
            return A_Index
    }
    return 0
}

Count(arr, substring) {
    res := 0
    Loop arr.Length {
        if InStr(arr[A_Index], substring)
            res += 1
    }
    return res
}