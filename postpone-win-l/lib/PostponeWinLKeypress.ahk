#Requires AutoHotkey v2.0
Persistent

#Include Keys.ahk ; keys state manager + AutoHotInterception
#Include Log.ahk
#Include Jsons.ahk

; PostponeWinLKeypress(50) ; test run
PostponeWinLKeypress(postponePeriod := 100, OnWinLCallback := false, debug := false) {
    if (debug)
        SetTimer DebugLog, 100

    ; scancodes of the keys used
    static sc := {
        l: GetKeySC("l"),
        lwin: GetKeySC("LWin"),
        rwin: GetKeySC("RWin")
    }

    keypressScheduled := 0

    ; key bindings
    for kbdid in Keys.keyboards {
        local id := kbdid
        Keys.AHI.SubscribeKeyboard(id, false, (scancode, s) => HandleOther(scancode, s, id))
        Keys.AHI.SubscribeKey(id, sc.lwin, true, (s) => HandleWin(sc.lwin, s, id)) ; block
        Keys.AHI.SubscribeKey(id, sc.rwin, true, (s) => HandleWin(sc.rwin, s, id)) ; block
        Keys.AHI.SubscribeKey(id, sc.l, true, (s) => HandleL(s, id)) ; block
    }

    HandleOther(code, state, kbd) {
        if (state == 1) ; press down
            Keys.Down(code, kbd)
        if (state == 0) ; release
            Keys.Up(code, kbd)
    }

    HandleWin(code, state, kbd) {
        if (state == 1) { ; press down
            Keys.Down(code, kbd)
            Keys.FakeDown(code, kbd)
        }
        if (state == 0) { ; release
            Keys.Up(code, kbd)
            if keypressScheduled
                return
            Keys.FakeUp(code, kbd)
        }
    }

    HandleL(state, kbd) {
        if (state == 1) { ; press down
            Keys.Down(sc.l, kbd)
            if (!keypressScheduled and WinKeyPressed() and Keys.PressedCount() == 2) {
                ScheduleFakeKeypress()
                return
            }
            Keys.FakeDown(sc.l, kbd)
        }
        if (state == 0) { ; release
            Keys.Up(sc.l, kbd)
            Keys.FakeUp(sc.l, kbd)
        }
    }

    ScheduleFakeKeypress() {
        keypressScheduled := 1
        if OnWinLCallback
            OnWinLCallback()
        SetTimer SendFakeKeypress, postponePeriod * -1
    }

    SendFakeKeypress() {
        keypressScheduled := 0
        Keys.FakeDown(sc.l) ; lock
        Sleep 1
        Keys.FakeUp(sc.l)
        Sleep 1
        if !Keys.IsPressed(sc.lwin)
            Keys.FakeUp(sc.lwin)
        if !Keys.IsPressed(sc.rwin)
            Keys.FakeUp(sc.rwin)
    }

    WinKeyPressed := () => Keys.IsPressed(sc.lwin) or Keys.IsPressed(sc.rwin)

    DebugLog() {
        keyboards := Jsons.Dump(Keys.keyboards, "  ")
        rl := Jsons.Dump(Keys.pressed, "  ")
        fk := Jsons.Dump(Keys.faked, "  ")
        Log('postponePeriod:' postponePeriod '`n---- keyboards:' keyboards '`n---- pressed:`n' rl '`n---- faked:`n' fk)
    }
}