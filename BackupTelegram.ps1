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

# === RICERCA EVENTI DI BACKUP ===
# ID 4 = successo, ID 5 = errore
$eventiBackup = Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-Backup'
    StartTime = $dataInizio
    ID = 4,5
} | Sort-Object TimeCreated -Descending

# === COSTRUZIONE MESSAGGIO ===
if ($eventiBackup.Count -eq 0) {
    $messaggio = "$Nome ⚠️ Nessun evento di backup trovato negli ultimi 90 minuti. Il backup potrebbe non essere stato eseguito!"
} else {
    $ultimoEvento = $eventiBackup[0]
    $stato = if ($ultimoEvento.Id -eq 4) { "$Nome ✅ *Backup completato con successo*" } else { "$Nome ❌ *Errore durante il backup*" }

    $messaggio = @"
$stato
🕒 Ora: $($ultimoEvento.TimeCreated)
💬 Evento: $($ultimoEvento.Message.Substring(0, [Math]::Min(400, $ultimoEvento.Message.Length)))...
"@
}

# === INVIO NOTIFICA TELEGRAM ===
$messaggioEncoded = [System.Net.WebUtility]::UrlEncode($messaggio)
$telegramUrl = "https://api.telegram.org/bot$telegramToken/sendMessage?chat_id=$chatId&message_thread_id=$threadId&text=$messaggioEncoded&parse_mode=Markdown"


try {
    Invoke-RestMethod -Uri $telegramUrl -Method Get | Out-Null
    Write-Host "✅ Notifica Telegram inviata con successo."
} catch {
    Write-Warning "❌ Errore durante l'invio della notifica Telegram: $_"
}
