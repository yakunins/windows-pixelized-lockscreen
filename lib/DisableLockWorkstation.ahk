DisableLockWorkstation() {
    RegWrite 0x00000001, "REG_DWORD", "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "DisableLockWorkstation"
}
