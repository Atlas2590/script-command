$hostname = $env:COMPUTERNAME
$OU = Get-ADOrganizationalUnit -Filter 'Name -notlike "Domain Controllers"' -SearchScope OneLevel
$client = $OU.Name  # <-- MODIFICA QUI il nome del cliente
$dataInizio = (Get-Date).AddHours(-24)

$eventi = Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-Backup'
    ID = 4,5
    StartTime = $dataInizio
} | Sort-Object TimeCreated -Descending

if ($eventi.Count -eq 0) {
    $status = "Nessun backup"
    $msg = "Nessun evento di backup trovato nelle ultime 24h"
    $event_time = (Get-Date).ToString("s")
} else {
    $ultimo = $eventi[0]
    $status = if ($ultimo.Id -eq 4) { "Successo" } else { "Errore" }
    $msg = $ultimo.Message.Substring(0, [Math]::Min(300, $ultimo.Message.Length))
    $event_time = $ultimo.TimeCreated.ToString("s")
}

$body = @{
    hostname = $hostname
    client = $client
    status = $status
    event_time = $event_time
    message = $msg
} | ConvertTo-Json -Compress

Invoke-RestMethod -Method Post -Uri "https://atlas54.altervista.org/backup-monitor/log.php" -Body $body -ContentType "application/json"
