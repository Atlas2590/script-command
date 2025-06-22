Write-Output "Inizio..."
 
# ===============================
# Script: BackupTelegram.ps1
# Scopo: Controlla esito backup Windows e invia notifica Telegram
# Orario previsto di esecuzione: ogni giorno alle 21:30
# ===============================

# === CONFIGURAZIONE ===
$telegramToken = "<INSERISCI_IL_TUO_TOKEN_BOT>"
$chatId = "<INSERISCI_IL_TUO_CHAT_ID>"

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
    $messaggio = "⚠️ Nessun evento di backup trovato negli ultimi 90 minuti. Il backup potrebbe non essere stato eseguito!"
} else {
    $ultimoEvento = $eventiBackup[0]
    $stato = if ($ultimoEvento.Id -eq 4) { "✅ *Backup completato con successo*" } else { "❌ *Errore durante il backup*" }

    $messaggio = @"
$stato
🕒 Ora: $($ultimoEvento.TimeCreated)
💬 Evento: $($ultimoEvento.Message.Substring(0, [Math]::Min(400, $ultimoEvento.Message.Length)))...
"@
}

# === INVIO NOTIFICA TELEGRAM ===
$messaggioEncoded = [System.Net.WebUtility]::UrlEncode($messaggio)
$telegramUrl = "https://api.telegram.org/bot$telegramToken/sendMessage?chat_id=$chatId&text=$messaggioEncoded&parse_mode=Markdown"

try {
    Invoke-RestMethod -Uri $telegramUrl -Method Get | Out-Null
    Write-Host "✅ Notifica Telegram inviata con successo."
} catch {
    Write-Warning "❌ Errore durante l'invio della notifica Telegram: $_"
}
