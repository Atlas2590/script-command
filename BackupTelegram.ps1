Write-Output "Inizio..."
 
# ===============================
# Script: BackupTelegram.ps1
# Scopo: Controlla esito backup Windows e invia notifica Telegram
# Orario previsto di esecuzione: ogni giorno alle 21:30
# ===============================

# === CONFIGURAZIONE ===
$telegramToken = "7542407879:AAHXjaj4OcZXZBaqXYfOl_wYXGIhIQxqjbM"
$chatId = "-1002864412111"
$threadId = 4  # Sostituisci con il vero ID del topic
$OU = Get-ADOrganizationalUnit -Filter 'Name -notlike "Domain Controllers"' -SearchScope OneLevel
$Nome = $OU.Name


# === DATA ===
$dataCorrente = Get-Date
$dataInizio = $dataCorrente.AddMinutes(-90) # Considera gli ultimi 90 minuti

# === DEBUG PRIMA DELLA RICERCA ===
Write-Host "DEBUG - Cercando eventi da: $dataInizio"

# === RICERCA EVENTI DI BACKUP ===
# ID 4 = successo, ID 5 = errore
$eventiBackup = @()

try {
    $eventiBackup = Get-WinEvent -FilterHashtable @{
        LogName = 'Microsoft-Windows-Backup'
        StartTime = $dataInizio
        ID = 4,5
    } -ErrorAction Stop

    if ($eventiBackup.Count -gt 0) {
        $eventiBackup = $eventiBackup | Sort-Object TimeCreated -Descending
        Write-Host "DEBUG - Trovati $($eventiBackup.Count) eventi."
    } else {
        Write-Host "DEBUG - Nessun evento trovato (lista vuota)."
    }
}
catch {
    Write-Warning "⚠️ Nessun evento trovato o log non accessibile. ($($_.Exception.Message))"
    $eventiBackup = @() # Fallback per proseguire
}

# === COSTRUZIONE MESSAGGIO ===
if ($eventiBackup.Count -eq 0) {
    $messaggio = "$Nome ⚠️ <b>Nessun evento di backup trovato negli ultimi 90 minuti</b>. Il backup potrebbe non essere stato eseguito!"
} else {
    $ultimoEvento = $eventiBackup[0]
    $stato = if ($ultimoEvento.Id -eq 4) {
        "$Nome ✅ <b>Backup completato con successo</b>"
    } else {
        "$Nome ❌ <b>Errore durante il backup</b>"
    }

    # Taglia il messaggio se troppo lungo
    $eventoTesto = $ultimoEvento.Message
    if ($eventoTesto.Length -gt 400) {
        $eventoTesto = $eventoTesto.Substring(0, 400) + "..."
    }

    # Escape di base per HTML (Telegram)
    $eventoTesto = $eventoTesto -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;'

    $messaggio = @"
$stato
🕒 Ora: $($ultimoEvento.TimeCreated)
💬 Evento: $eventoTesto
"@
}

# === INVIO NOTIFICA TELEGRAM ===

# Codifica per URL
$messaggioEncoded = [System.Net.WebUtility]::UrlEncode($messaggio)

# Costruzione URL Telegram
$telegramUrl = "https://api.telegram.org/bot$telegramToken/sendMessage?chat_id=$chatId&message_thread_id=$threadId&text=$messaggioEncoded&parse_mode=HTML"

try {
    Invoke-RestMethod -Uri $telegramUrl -Method Get | Out-Null
    Write-Host "✅ Notifica Telegram inviata con successo."
} catch {
    Write-Warning "❌ Errore durante l'invio della notifica Telegram: $_"
}

