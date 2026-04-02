; Ctrl+Alt+Del is a kernel-level Secure Attention Sequence (SAS) that cannot be
; intercepted or hooked by user-mode applications. By the time any detectable
; event fires (session lock, LogonUI.exe start), the desktop is already hidden.
; The lock screen screenshot is expected to be already set by handleIdleLocking
; or handleKeypressLocking before the user presses Ctrl+Alt+Del → Lock.

HandleCtrlAltDelLocking(cfg) {
}
