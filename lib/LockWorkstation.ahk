LockWorkstation(delay := 50) {
    if (delay > 0)
        Sleep(delay)
    DllCall("user32\LockWorkStation")
}
