; register and unregister new task for Task Scheduler © gihub.com/yakunins
#Requires AutoHotkey v2.0

PS := 'powershell.exe'
defaultUser := A_ComputerName . '\' . A_UserName

RegisterTaskOnLock(taskName, executablePath, user := defaultUser, debug := false) {
    stateChangeTrigger := "(Get-CimClass"
        . " -Namespace ROOT\Microsoft\Windows\TaskScheduler"
        . " -ClassName MSFT_TaskSessionStateChangeTrigger)"

    onLockTrigger := "New-CimInstance -CimClass " stateChangeTrigger
        . " -Property @{StateChange=7}" ; on workstation lock, https://learn.microsoft.com/en-us/windows/win32/api/taskschd/ne-taskschd-task_session_state_change_type
        . " -ClientOnly"

    ; unused
    onUnlockTrigger := "New-CimInstance -CimClass " stateChangeTrigger
        . " -Property @{StateChange=8}" ; TASK_SESSION_STATE_CHANGE_TYPE.TASK_SESSION_UNLOCK
        . " -ClientOnly "

    cmd := "`""
        . (debug ? "try{" : "")
        . "Register-ScheduledTask -TaskName '" taskName "'"
        . " -Trigger (" onLockTrigger ")"
        . " -User '" user "'"
        . " -Action (New-ScheduledTaskAction -Execute '" executablePath "')"
        . ";"
        . (debug ? "Write-Host 'RegisterTaskOnLock() done.';" : "")
        . (debug ? "}catch{" : "")
        . (debug ? "Write-Host 'RegisterTaskOnLock() error:';" : "")
        . (debug ? "Write-Host $_;" : "")
        . (debug ? "}" : "")
        . "`""

    if (debug) {
        A_Clipboard := cmd
        Run(PS . ' -noexit -command ' . cmd)
        return
    }
    Run(PS . ' -command ' . cmd, , 'Hide')
}

UnregisterTaskOnLock(taskName, debug := false) {
    cmd := "`""
        . (debug ? "try{" : "")
        . "Unregister-ScheduledTask -TaskName '" taskName "'"
        . " -Confirm:$false"
        . ";"
        . (debug ? "Write-Host 'UnregisterTaskOnLock() done.';" : "")
        . (debug ? "}catch{" : "")
        . (debug ? "Write-Host 'UnregisterTaskOnLock() error:';" : "")
        . (debug ? "Write-Host $_;" : "")
        . (debug ? "}" : "")
        . "`""

    if (debug) {
        A_Clipboard := cmd
        Run(PS . ' -noexit -command ' . cmd)
        return
    }
    Run(PS . ' -command ' . cmd, , 'Hide')
}