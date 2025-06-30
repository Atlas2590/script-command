# === CONFIG ===
$scriptPath = "https://raw.githubusercontent.com/Atlas2590/script-command/refs/heads/main/sendBackupLog.ps1"
$taskName = "BackupTelegramPolling"

# === CREA LA TASK CHE ESEGUE LO SCRIPT OGNI 5 MINUTI ===
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Hours 23)
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Force
Write-Host "✅ Task '$taskName' creata. Verifica che lo script sia in: $scriptPath"
