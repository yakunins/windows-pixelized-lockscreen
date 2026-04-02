; Converts human-readable hotkey like "Win+L" into object {modifiers: "#", key: "l"}
ParseHotkey(hotkeyStr) {
    modifiers := ""
    key := ""
    parts := StrSplit(hotkeyStr, "+")
    for i, part in parts {
        part := Trim(part)
        low := StrLower(part)
        if (low = "ctrl" || low = "control")
            modifiers .= "^"
        else if (low = "alt")
            modifiers .= "!"
        else if (low = "shift")
            modifiers .= "+"
        else if (low = "win" || low = "windows")
            modifiers .= "#"
        else
            key := low
    }
    return {modifiers: modifiers, key: key}
}
