# === CONFIG ===
$scriptPath = "irm https://raw.githubusercontent.com/Atlas2590/script-command/refs/heads/main/sendBackupLog.ps1 | iex"
$taskName = "BackupLogPolling"

# === CREA LA TASK CHE ESEGUE LO SCRIPT OGNI 3 VOLTE AL GIORNO ===
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -Command `"$scriptPath`""
$trigger1 = New-ScheduledTaskTrigger -Daily -At 23pm
$trigger2 = New-ScheduledTaskTrigger -Daily -At 3am
$trigger3 = New-ScheduledTaskTrigger -Daily -At 8am
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger @($trigger1, $trigger2, $trigger3) -Principal $principal -Force
Write-Host "✅ Task '$taskName' creata. Verifica che lo script sia in: Task Scheduler"
