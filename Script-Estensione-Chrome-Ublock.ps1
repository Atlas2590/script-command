# === CONFIGURAZIONI ===
$language = "it-IT"  # cambia in "en-US" se il tuo sistema è in inglese
$downloadUrl = "https://dl.google.com/dl/edgedl/chrome/policy/policy_templates.zip"
$tempPath = "$env:TEMP\chrome_admx"
$policyDefPath = "$env:SystemRoot\PolicyDefinitions"

# === CREAZIONE CARTELLE TEMPORANEE ===
if (!(Test-Path $tempPath)) {
    New-Item -ItemType Directory -Path $tempPath | Out-Null
}

# === SCARICA IL PACCHETTO ZIP ===
$zipFile = "$tempPath\policy_templates.zip"
Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFile

# === ESTRAI I FILE NECESSARI ===
Expand-Archive -Path $zipFile -DestinationPath $tempPath -Force

# === PERCORSI INTERNI ===
$admxSource = Get-ChildItem -Path "$tempPath\windows\admx" -Filter "chrome.admx" -Recurse | Select-Object -First 1
$admlSource = Get-ChildItem -Path "$tempPath\windows\admx\$language\chrome.adml" -Recurse | Select-Object -First 1

# === VERIFICA FILE E COPIA ===
if ($admxSource -and $admlSource) {
    Copy-Item $admxSource.FullName -Destination "$policyDefPath\" -Force
    Copy-Item $admlSource.FullName -Destination "$policyDefPath\$language\" -Force
    Write-Host "✅ File ADMX/ADML copiati correttamente in PolicyDefinitions."
} else {
    Write-Error "❌ File chrome.admx o chrome.adml non trovati. Controlla il pacchetto o la lingua."
    exit
}


$Dominio = Read-Host "Inserisci il nome del dominio"
# Inserire il nome del dominio

# Estensione da installare forzatamente
$GpoName = "Estensione Chrome Ublock"
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

