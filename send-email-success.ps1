
$OU = Get-ADOrganizationalUnit -Filter 'Name -notlike "Domain Controllers"' -SearchScope OneLevel
$NomeOU = $OU.Name
# RECUPERA IL NOME DELLA SCUOLA DALL'UNITA' ORGANIZZATIVA PADRE

#RECUPERA LE CREDENZIALI DI ACCESSO
Import-Module CredentialManager

$cred = Get-StoredCredential -Target "mail"

# INVIA EMAIL
$From = "report@sistema54.com"
$To = "report@sistema54.com"
$Subject = "SERVER $NomeOU Success Backup"
$Body = "Backup completo con Windows Server Backup effettuato con successo."
$Password = $cred.Password
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "report@sistema54.com", $Password
Send-MailMessage -From $From -To $To -Subject $Subject -Body $Body -SmtpServer "smtp.gmail.com" -port 587 -UseSsl -Credential $Credential
