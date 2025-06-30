$statoFile = "C:\Scripts\lastBackupEventMonitor.txt"

# Crea cartella se non esiste
$cartella = Split-Path $statoFile
if (-not (Test-Path $cartella)) {
    New-Item -ItemType Directory -Path $cartella -Force | Out-Null
    Write-Host "Cartella creata: $cartella"
}

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
    $eventoUnico = "NoEvent_$event_time"
} else {
    $ultimo = $eventi[0]
    $status = if ($ultimo.Id -eq 4) { "Successo" } else { "Errore" }
    $msg = $ultimo.Message.Substring(0, [Math]::Min(300, $ultimo.Message.Length))
    $event_time = $ultimo.TimeCreated.ToString("s")
    $eventoUnico = "$($ultimo.Id)_$($ultimo.TimeCreated.ToString('yyyyMMddHHmmss'))"
}

# Leggi ultimo evento inviato
$ultimoEventoInviato = ""
if (Test-Path $statoFile) {
    $ultimoEventoInviato = Get-Content $statoFile -ErrorAction SilentlyContinue
}

if ($eventoUnico -eq $ultimoEventoInviato) {
    Write-Host "Evento già inviato: $eventoUnico. Esco senza inviare."
    exit 0
}

$body = @{
    hostname = $hostname
    client = $client
    status = $status
    event_time = $event_time
    message = $msg
} | ConvertTo-Json -Compress

try {
    Invoke-RestMethod -Method Post -Uri "https://atlas54.altervista.org/backup-monitor/log.php" -Body $body -ContentType "application/json"
    Write-Host "✅ Dati inviati con successo."
    # Aggiorna file di stato solo se invio OK
    $eventoUnico | Out-File -FilePath $statoFile -Encoding ascii -Force
} catch {
    Write-Warning "❌ Errore nell'invio dei dati: $_"
}
