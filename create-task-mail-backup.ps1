Write-Output "Inizio..."
# Set Name of Task
[string]$TaskName = "Send Mail Backup Success"

# Path ps1
$PSCommand = 'iex (irm https://raw.githubusercontent.com/Atlas2590/script-command/refs/heads/main/send-email-success.ps1)'

# Action to Trigger:
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ep bypass -command `"$PSCommand`""

# Trigger on Event
$CIMTriggerClass = Get-CimClass -ClassName MSFT_TaskEventTrigger -Namespace Root/Microsoft/Windows/TaskScheduler:MSFT_TaskEventTrigger
$Trigger = New-CimInstance -CimClass $CIMTriggerClass -ClientOnly
$Trigger.Subscription = @"
<QueryList><Query Id="0" Path="Microsoft-Windows-Backup"><Select Path="Microsoft-Windows-Backup">*[System[Provider[@Name='Backup'] and EventID=14]]</Select></Query></QueryList>
"@
$Trigger.Delay = 'PT1M'
$Trigger.Enabled = $True

# Run as System
$Prin = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest

# Stop Task if runs more than 60 minutes
$Timeout = (New-TimeSpan -Minutes 60)

# Other Settings on the Task
$settings = New-ScheduledTaskSettingsSet -RunOnlyIfNetworkAvailable -StartWhenAvailable:$false -DontStopIfGoingOnBatteries -ExecutionTimeLimit $Timeout
$settings.CimInstanceProperties.Item('MultipleInstances').Value = 3 # 3 corrsponds to 'Stop the existig instance'


# Create the Task
$task = New-ScheduledTask -Action $action -Principal $Prin -Trigger $Trigger -Settings $settings

# Register Task with Windows
Register-ScheduledTask -TaskName $TaskName -InputObject $task -Force -ErrorAction SilentlyContinue


# Crea task send mail backup failure

[String]$TaskName = "Send Mail Backup Failed"
#Set Name of Task

# Path ps1
$PSCommand = 'iex (irm https://raw.githubusercontent.com/Atlas2590/script-command/refs/heads/main/send-email-failed.ps1)'

# Action to Trigger:
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ep bypass -command `"$PSCommand`""

# Trigger on Event
$CIMTriggerClass = Get-CimClass -ClassName MSFT_TaskEventTrigger -Namespace Root/Microsoft/Windows/TaskScheduler:MSFT_TaskEventTrigger
$Trigger = New-CimInstance -CimClass $CIMTriggerClass -ClientOnly
$Trigger.Subscription = @"
<QueryList>
  <Query Id="0" Path="Microsoft-Windows-Backup">
    <Select Path="Microsoft-Windows-Backup">*[System[Provider[@Name='Microsoft-Windows-Backup'] and (EventID=5 or EventID=7 or EventID=8 or EventID=9 or EventID=17 or EventID=22 or EventID=49 or EventID=50 or EventID=52 or EventID=100 or EventID=517 or EventID=518 or EventID=521 or EventID=527 or EventID=528 or EventID=544 or EventID=545 or EventID=546 or EventID=561 or EventID=564 or EventID=612)]]</Select>
  </Query>
</QueryList>
"@
$Trigger.Delay = 'PT1M'
$Trigger.Enabled = $True

# Run as System
$Prin = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest

# Stop Task if runs more than 60 minutes
$Timeout = (New-TimeSpan -Minutes 60)

#Other Settings on the Task
$settings = New-ScheduledTaskSettingsSet -RunOnlyIfNetworkAvailable -StartWhenAvailable:$false -DontStopIfGoingOnBatteries -ExecutionTimeLimit $Timeout
$settings.CimInstanceProperties.Item('MultipleInstances').Value = 3 # 3 corrsponds to 'Stop the existig instance'


# Create the Task
$task = New-ScheduledTask -Action $action -Principal $Prin -Trigger $Trigger -Settings $settings

# Register Task with Windows
Register-ScheduledTask -TaskName $TaskName -InputObject $task -Force -ErrorAction SilentlyContinue

# Installazione NuGet
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-PackageProvider -Name NuGet -Force -Scope AllUsers
# Configurare il repository PSGallery come attendibile
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

Write-Output "Controllo modulo CredentialManager" 
# controllo modulo CredentialManager installato
if (Get-Module -ListAvailable -Name CredentialManager) {
Write-Output "modulo installato"
}else{
Write-Output "modulo non installato, sto installando..."
Install-Module -Name CredentialManager -Force -AllowClobber -Scope AllUsers
}

Write-Output "Aggiunta credenziali"
# Aggiungi una credenziale generica
New-StoredCredential -Target "mail" -UserName "report@sistema54.com" -Password "Kaisersoser@54" -Persist LocalMachine
