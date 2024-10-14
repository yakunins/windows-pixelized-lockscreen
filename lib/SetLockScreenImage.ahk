; Set and unset lock screen background with Powershell command
#Requires AutoHotkey v2.0

PS := 'powershell.exe'
defaultImagePath := A_ScriptDir . '\screenshot.png'
defaultRegistryItem := 'LockScreenImagePath'
defaultRegistryPath := 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP'
;defaultRegistryPath_unused_1 := 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP'
;defaultRegistryPath_unused_2 := 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Personalization'

global registryState := {
	pathExist: 0, ; -2ms
}

; Setup registry value for lock screen image
SetLockScreenImage(
	imagePath := defaultImagePath,
	registryPath := defaultRegistryPath,
	registryItem := defaultRegistryItem,
	debug := false
) {
	if !FileExist(imagePath) {
		if debug
			MsgBox "SetLockScreenImage(), no such file: " imagePath
		return
	}

	if (registryState.pathExist == 0)
		CreateRegistryPath(registryPath, debug)

	cmd := "`""
		. (debug ? "try{" : "")
		. "Set-ItemProperty -Path '" registryPath "' "
		. "-Name '" registryItem "' "
		. "-Value '" imagePath "';"
		. (debug ? "Write-Host 'SetLockScreenImage() done, imagePath: " imagePath "';" : "")
		. (debug ? "}catch{" : "")
		. (debug ? "Write-Host 'SetLockScreenImage() error:';" : "")
		. (debug ? "Write-Host $_;" : "")
		. (debug ? "}" : "")
		. "`""

	if (debug) {
		try {
			A_Clipboard := cmd
		}
		Run(PS . ' -noexit -command ' . cmd)
		return
	}
	Run(PS . ' -command ' . cmd, , 'Hide')
}

CreateRegistryPath(registryPath := defaultRegistryPath, debug := false) {
	cmd := "`""
		. (debug ? "try{" : "")
		. "  if(!(Test-Path '" registryPath "')){"
		. "    New-Item -Path '" registryPath "' -Force;"
		. "    $result = 'new registry.path was created';"
		. "  }else{ $result = 'registry.path already exist, skipped'; }"
		. (debug ? "Write-Host 'CreateRegistryPath(), done:';" : "")
		. (debug ? "Write-Host $result;" : "")
		. (debug ? "}catch{" : "")
		. (debug ? "Write-Host 'CreateRegistryPath() error:';" : "")
		. (debug ? "Write-Host $_;" : "")
		. (debug ? "}" : "")
		. "`""

	if (debug) {
		try {
			A_Clipboard := cmd
		}
		Run(PS . ' -noexit -command ' . cmd)
		return
	}
	Run(PS . ' -command ' . cmd, , 'Hide')
	registryState.pathExist := 1
}

RemoveRegistryPath(registryPath := defaultRegistryPath, debug := false) {
	cmd := "`""
		. (debug ? "try{" : "")
		. "  if (Test-Path '" registryPath "') {"
		. "    Remove-Item -Path '" registryPath "' -Force;"
		. "    $result = 'registryPath was removed';"
		. "  }else{ $result = 'registryPath was not found!'; }"
		. (debug ? "Write-Host 'RemoveRegistryPath() done:';" : "")
		. (debug ? "Write-Host $result;" : "")
		. (debug ? "}catch{" : "")
		. (debug ? "Write-Host 'RemoveRegistryPath() error:';" : "")
		. (debug ? "Write-Host $_;" : "")
		. (debug ? "}" : "")
		. "`""

	if (debug) {
		try {
			A_Clipboard := cmd
		}
		Run(PS . ' -noexit -command ' . cmd)
		return
	}
	Run(PS . ' -command ' . cmd, , 'Hide')
	registryState.pathExist := 0
}

UnsetLockScreenImage(
	registryPath := defaultRegistryPath,
	registryItem := defaultRegistryItem,
	debug := false
) {
	testItemProperty := "(Get-Item '" registryPath "').Property -contains '" registryItem "'"
	; testItemProperty := "(Get-Item -Path '" registryPath "').GetValue('" registryItem "') -ne $null"

	cmd := "`""
		. (debug ? "try{" : "")
		. "  if(" testItemProperty "){"
		. "    Remove-ItemProperty -Path '" registryPath "' -Name '" registryItem "';"
		. "    $result = 'itemProperty was removed';"
		. "  }else{ $result = 'itemProperty was not found!'; }"
		. (debug ? "Write-Host 'UnsetLockScreenImage() done:';" : "")
		. (debug ? "Write-Host $result;" : "")
		. (debug ? "}catch{" : "")
		. (debug ? "Write-Host 'UnsetLockScreenImage() error:';" : "")
		. (debug ? "Write-Host $_;" : "")
		. (debug ? "}" : "")
		. "`""

	if (debug) {
		try {
			A_Clipboard := cmd
		}
		Run(PS . ' -noexit -command ' . cmd)
		return
	}
	Run(PS . ' -command ' . cmd, , 'Hide')
}