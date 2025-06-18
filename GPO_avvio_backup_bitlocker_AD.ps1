
$ScriptUrl = "https://raw.githubusercontent.com/Atlas2590/script-command/main/bitlocker_backup_ad.ps1"
$ScriptName = "bitlocker_backup_ad.ps1"
$GpoName = "Default Domain Policy"
﻿
try {
    # IMPORTA MODULO GPO
    Import-Module GroupPolicy -ErrorAction Stop

    # OTTIENI DOMINIO E GUID DELLA GPO
    $Domain = (Get-WmiObject Win32_ComputerSystem).Domain
    $Gpo = Get-GPO -Name $GpoName -ErrorAction Stop
    $GpoGuid = $Gpo.Id.ToString("B").ToUpper()

    # PERCORSO CARTELLA STARTUP
    $StartupPath = "\\$Domain\SYSVOL\$Domain\Policies\$GpoGuid\Machine\Scripts\Startup"
    $ScriptFullPath = Join-Path $StartupPath $ScriptName
    $IniFile = Join-Path $StartupPath "scripts.ini"

    # CREA CARTELLA SE NON ESISTE
    if (-not (Test-Path $StartupPath)) {
        New-Item -ItemType Directory -Path $StartupPath -Force | Out-Null
    }

    # SCARICA SCRIPT SE NON ESISTE
    if (-not (Test-Path $ScriptFullPath)) {
        Invoke-WebRequest -Uri $ScriptUrl -OutFile $ScriptFullPath -UseBasicParsing -ErrorAction Stop
        Write-Host "✔ Script scaricato: $ScriptFullPath"
    } else {
        Write-Host "✔ Script già presente: $ScriptFullPath"
    }

    # CREA scripts.ini SE NON ESISTE
    if (-not (Test-Path $IniFile)) {
        @"
[Startup]
0CmdLine=$ScriptName
0Parameters=
"@ | Out-File -FilePath $IniFile -Encoding ASCII
        Write-Host "📝 File scripts.ini creato con lo script."
    }
    else {
        # AGGIUNGI SCRIPT SOLO SE NON ESISTE
        $content = Get-Content $IniFile -Raw
        if ($content -notmatch [regex]::Escape($ScriptName)) {
            $indices = ([regex]::Matches($content, '(\d+)CmdLine') | ForEach-Object { [int]$_.Groups[1].Value })
            $newIndex = if ($indices.Count -gt 0) { ($indices | Measure-Object -Maximum).Maximum + 1 } else { 0 }
            Add-Content -Path $IniFile -Value "$newIndex`CmdLine=$ScriptName"
            Add-Content -Path $IniFile -Value "$newIndex`Parameters="
            Write-Host "📝 Script aggiunto a scripts.ini."
        }
        else {
            Write-Host "✔ Script già registrato in scripts.ini."
        }
    }

    Write-Host "`n✅ Script correttamente configurato nella GPO '$GpoName'."

} catch {
    Write-Error "❌ Errore: $_"
    exit 1
}
