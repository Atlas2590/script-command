
$volumi = Get-BitLockerVolume
# Salva chiavi di ripristino e key package BitLocker in AD

foreach ($volume in $volumi) {
    $mountPoint = $volume.MountPoint
    foreach ($protector in $volume.KeyProtector) {
        if ($protector.KeyProtectorType -eq "RecoveryPassword") {
            try {
                Backup-BitLockerKeyProtector -MountPoint $mountPoint -KeyProtectorId $protector.KeyProtectorId -ErrorAction Stop
                "Backup recovery key su $mountPoint OK" | Out-File "C:\BitLocker_Backup.log" -Append

                # Backup del key package (se supportato)
                if ($protector.KeyPackage) {
                    "Key package già incluso su $mountPoint" | Out-File "C:\BitLocker_Backup.log" -Append
                } else {
                    try {
                        Backup-BitLockerKeyProtector -MountPoint $mountPoint -KeyProtectorId $protector.KeyProtectorId -KeyPackage -ErrorAction Stop
                        "Backup key package su $mountPoint OK" | Out-File "C:\BitLocker_Backup.log" -Append
                    } catch {
                        "Errore nel backup key package su $mountPoint: $_" | Out-File "C:\BitLocker_Backup.log" -Append
                    }
                }

            } catch {
                " Errore nel backup recovery key su $mountPoint: $_" | Out-File "C:\BitLocker_Backup.log" -Append
            }
        }
    }
}
