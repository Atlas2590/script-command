
$scriptURL = "https://raw.githubusercontent.com/Atlas2590/script-command/refs/heads/main/BackupTelegram.ps1"
$scriptPath = "$env:ProgramData\BackupNotify\backup-telegram.ps1"
$taskName = "BackupTelegramNotify"
﻿# === CONFIGURAZIONE ===

# === CREA CARTELLA E SCARICA LO SCRIPT ===
New-Item -ItemType Directory -Path (Split-Path $scriptPath) -Force | Out-Null
Invoke-WebRequest -Uri $scriptURL -OutFile $scriptPath -UseBasicParsing

# === CREA LA TASK ===
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
$trigger = New-ScheduledTaskTrigger -AtStartup  # Placeholder, lo sostituiremo con l’evento

# Imposta autorizzazioni
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Crea la task base
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal

# Rimuovi il trigger temporaneo
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
Register-ScheduledTask -TaskName $taskName -Xml (Get-ScheduledTask -TaskName $taskName | Export-ScheduledTask | Out-String) -Force

# === CREA TRIGGER BASATO SU EVENTO ===
$eventXML = @"
<QueryList>
  <Query Id="0" Path="Microsoft-Windows-Backup/Operational">
    <Select Path="Microsoft-Windows-Backup/Operational">
      *[System[(EventID=4 or EventID=5 or EventID=49)]]
    </Select>
  </Query>
</QueryList>
"@

$taskDefinition = New-ScheduledTask
$taskDefinition.Actions = $action
$taskDefinition.Principal = $principal

$trigger = New-ScheduledTaskTrigger -AtStartup  # Placeholder necessario
$taskDefinition.Triggers.Clear()
$taskDefinition.Triggers.Add((New-ScheduledTaskTrigger -AtStartup)) # Dummy trigger da rimuovere dopo

# Registra la task con dummy trigger
Register-ScheduledTask -TaskName $taskName -InputObject $taskDefinition -Force

# Aggiungi vero trigger con EventTrigger (non supportato da cmdlet, si usa schtasks)
$xmlEventFilter = $eventXML.Replace('"', '""')
$cmd = "schtasks /Create /TN `"$taskName`" /TR `"powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"`" /SC ONEVENT /EC `"Microsoft-Windows-Backup/Operational`" /MO `"$xmlEventFilter`" /RU SYSTEM /F"
Invoke-Expression $cmd
