
# Set Name of Task
[string]$TaskName = "Send Mail Backup Success"

# Path ps1
$PSCommand = 'iex (irm https://github.com/Atlas2590/script-command/send-mail-success.ps1)'

# Action to Trigger:
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ep bypass -command `"$PSCommand`""

# Trigger on Event
$CIMTriggerClass = Get-CimClass -ClassName MSFT_TaskEventTrigger -Namespace Root/Microsoft/Windows/TaskScheduler:MSFT_TaskEventTrigger
$Trigger = New-CimInstance -CimClass $CIMTriggerClass -ClientOnly
$Trigger.Subscription = @"
<QueryList><Query Id="0" Path="Microsoft-Windows-Backup"><Select Path="Microsoft-Windows-Backup">*[Microsoft-Windows-Backup[Provider[@Name='Backup'] and EventID=14]]</Select></Query></QueryList>
"@
$Trigger.Delay = 'PT1M'
$Trigger.Enabled = $True

# Run as System
$Prin = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest

# Stop Task if runs more than 60 minutes
$Timeout = (New-TimeSpan -Minutes 60)

# Other Settings on the Task
$settings = New-ScheduledTaskSettingsSet -RunOnlyIfNetworkAvailable -StartWhenAvailable -DontStopIfGoingOnBatteries -ExecutionTimeLimit $Timeout
$settings.CimInstanceProperties.Item('MultipleInstances').Value = 3 # 3 corrsponds to 'Stop the existig instance'


# Create the Task
$task = New-ScheduledTask -Action $action -Principal $Prin -Trigger $Trigger -Settings $settings

# Register Task with Windows
Register-ScheduledTask -TaskName $TaskName -InputObject $task -Force -ErrorAction SilentlyContinue
