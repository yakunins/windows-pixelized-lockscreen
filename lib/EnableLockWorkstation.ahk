EnableLockWorkstation() {
    RegWrite 0x00000000, "REG_DWORD", "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "DisableLockWorkstation"
}
