
$Dominio = Read-Host "Inserisci il nome del dominio"
# Inserire il nome del dominio

# Estensione da installare forzatamente
$OUPath = "DC=$Dominio,DC=local"
$ExtensionID = "gcejgfdapijlfcapbnlipkpdedclclgl"
$UpdateUrl = "https://clients2.google.com/service/update2/crx"
$keyPath = "HKLM\Software\Policies\Google\Chrome\ExtensionInstallForcelist"

# === Creazione GPO ===
try {
    $gpo = New-GPO -Name $GpoName -ErrorAction Stop
    Write-Host "✅ GPO '$GpoName' creata con successo."
} catch {
    Write-Warning "⚠️ GPO già esistente o errore durante la creazione: $_"
    $gpo = Get-GPO -Name $GpoName
}

# === Collegamento alla OU ===
try {
    New-GPLink -Name $GpoName -Target $OUPath -ErrorAction Stop
    Write-Host "🔗 GPO '$GpoName' collegata a '$OUPath'"
} catch {
    Write-Error "❌ Errore nel collegamento della GPO alla OU: $_"
}

# === Imposta il valore di registro nella GPO ===
Set-GPRegistryValue -Name $GpoName -Key $keyPath -ValueName "1" -Type String -Value "$ExtensionID;$UpdateUrl"
Write-Host "🛠️  Estensione Chrome configurata per l'installazione forzata."

Write-Host "`n✅ Completato. La GPO '$GpoName' è attiva."
