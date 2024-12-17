# Funzione per mostrare il menu
function Show-Menu {
    cls
    Write-Host "========================================"
    Write-Host "         MENU PRINCIPALE"
    Write-Host "========================================"
    Write-Host "1 - Active Directory - Crea Utente, cartella, condivisione e collegamento"
    Write-Host "2 - Crea Utente FileZilla"
    Write-Host "3 - Crea Unità Organizzative"
    Write-Host "Q - Esci"
    Write-Host "========================================"
}

# Funzione per il Comando 1
function Esegui-Comando1 {
    Write-Host "Hai scelto Comando 1"
    # Inserisci qui il codice per il Comando 1
    $Name = Read-Host "Please enter your first name"
 $Cognome = Read-Host "Please enter your last name"
 $Password = Read-Host "Please enter your password"
Function Create-ADUser {
 

    # Crea l'utente in Active Directory
    New-ADUser -SamAccountName $Cognome `
               -GivenName $Name `
               -Surname $Cognome `
               -Name "$Name $Cognome" `
		-UserPrincipalName "$Cognome@securedomain.local" `
             -DisplayName "$Name $Cognome" `
               -Path "OU=Utenti_User,OU=GRAGNANO,DC=securedomain,DC=local" `
               -AccountPassword (ConvertTo-SecureString $Password -AsPlainText -Force) `
               -Enabled $true `
               -PassThru
    Write-Host "Creato utente: $Name $Cognome"
}


# Creare l'utente in Active Directory
Create-ADUser


MD F:\DATI\$Cognome

net share $Cognome=F:\DATI\$Cognome /grant:Administrators,full /grant:securedomain\$Cognome,change /CACHE:none
MD F:\DATI\$Cognome\SCANSIONI

$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("F:\DATI\CED\MDS\Policy_folder\$Cognome.lnk")
$Shortcut.TargetPath = "\\svrcentrale\$Cognome"
$Shortcut.Save()

}

# Funzione per il Comando 2
function Esegui-Comando2 {
    Write-Host "Hai scelto Comando 2"
    # Inserisci qui il codice per il Comando 2
     $CognomeFileZilla = Read-Host "Cognome per filezilla"
    
     $xmlFilePath = "C:\Program Files (x86)\FileZilla Server\FileZilla Server.xml"

[xml]$xmlDoc = Get-Content -Path $xmlFilePath

    $userName = $CognomeFileZilla  # Nome dell'utente
    $folderPath = "F:/DATI/$Cognome/SCANSIONI"  # Cartella a cui l'utente avrà accesso
    $fileReadPermission = "1"  # Permesso di lettura (1 = abilitato, 0 = disabilitato)
    $fileWritePermission = "1"  # Permesso di scrittura

   if ($xmlDoc.FileZillaServer.Users -eq $null) {
        Write-Host "Nodo <Users> non trovato. Creazione del nodo <Users>."
        $usersNode = $xmlDoc.CreateElement("Users")
        $xmlDoc.FileZillaServer.AppendChild($usersNode)
    } else {
        $usersNode = $xmlDoc.FileZillaServer.Users
        Write-Host "Nodo <Users> trovato."
	}
    

$userNode = $xmlDoc.CreateElement("User")
$userNode.SetAttribute("Name", $userName)



$passwordNode = $xmlDoc.CreateElement("Option")
    $passwordNode.SetAttribute("Name","Pass")  # La password sarà in chiaro
    $passwordNode.InnerText = $userName  # La password sarà in chiaro
    $userNode.AppendChild($passwordNode)
$usersNode.AppendChild($userNode)


$permissionsNode = $xmlDoc.CreateElement("Permissions")
$userNode.AppendChild($permissionsNode)
$permissionNode = $xmlDoc.CreateElement("Permission")
$permissionNode.SetAttribute("Dir",$FolderPath)
$permissionsNode.AppendChild($permissionNode)

$fileReadNode = $xmlDoc.CreateElement("Option")
	$fileReadNode.SetAttribute("Name","FileRead") #permesso di lettura
	$fileReadNode.InnerText = 1 #spunta il permesso
	$permissionNode.AppendChild($fileReadNode)

$fileWriteNode = $xmlDoc.CreateElement("Option")
	$fileWriteNode.SetAttribute("Name","FileWrite") #permesso di scrittura
	$fileWriteNode.InnerText = 1 #spunta il permesso
	$permissionNode.AppendChild($fileWriteNode)

$fileDeleteNode = $xmlDoc.CreateElement("Option")
	$fileDeleteNode.SetAttribute("Name","FileDelete") #permesso di Delete
	$fileDeleteNode.InnerText = 1 #spunta il permesso
	$permissionNode.AppendChild($fileDeleteNode)

$fileAppendNode = $xmlDoc.CreateElement("Option")
	$fileAppendNode.SetAttribute("Name","FileAppend") #permesso di Append
	$fileAppendNode.InnerText = 1 #spunta il permesso
	$permissionNode.AppendChild($fileAppendNode)

$dirCreateNode = $xmlDoc.CreateElement("Option")
	$dirCreateNode.SetAttribute("Name","DirCreate") #permesso di dirCreate
	$dirCreateNode.InnerText = 1 #spunta il permesso
	$permissionNode.AppendChild($dirCreateNode)

$dirDeleteNode = $xmlDoc.CreateElement("Option")
	$dirDeleteNode.SetAttribute("Name","DirDelete") #permesso di dirDelete
	$dirDeleteNode.InnerText = 1 #spunta il permesso
	$permissionNode.AppendChild($dirDeleteNode)

$dirListNode = $xmlDoc.CreateElement("Option")
	$dirListNode.SetAttribute("Name","DirList") #permesso di dirList
	$dirListNode.InnerText = 1 #spunta il permesso
	$permissionNode.AppendChild($dirListNode)

$dirSubdirsNode = $xmlDoc.CreateElement("Option")
	$dirSubdirsNode.SetAttribute("Name","DirSubdirs") #permesso di dirSubdirs
	$dirSubdirsNode.InnerText = 1 #spunta il permesso
	$permissionNode.AppendChild($dirSubdirsNode)

$isHomeNode = $xmlDoc.CreateElement("Option")
	$isHomeNode.SetAttribute("Name","IsHome") #permesso di isHome
	$isHomeNode.InnerText = 1 #spunta il permesso
	$permissionNode.AppendChild($isHomeNode)


$xmlDoc.Save($xmlFilePath)
Restart-Service -Name "FileZilla Server"

}

# Funzione per il Comando 3
function Esegui-Comando3 {
    Write-Host "Hai scelto Comando 3"
    # Inserisci qui il codice per il Comando 3
    $parentOU = Read-Host "Inserisci il nome dell'unità organizzativa principale"
    $parentOU_DN = "OU=$parentOU,DC=securedomain,DC=local" #modifica il dominio se necessario

    #Creazione della parent OU
    try {
        New-ADOrganizationalUnit -Name $parentOU -Path "DC=securedomain,DC=local"
        Write-Host "Unità Organizzativa '$parentOU' creata con successo!"
    }
    catch{
        Write-Host "Errore durante la creazione dell'OU '$parentOU': $_"
        return
    }

#Creazione delle OUs figlie
$childOUDN = "OU=Utenti_User,$parentOU_DN"

    try {
        New-ADOrganizationalUnit -Name "Utenti_User" -Path $parentOU_DN
        Write-Host "OU figlia Utenti_User creata con successo in '$parentOU'."
    }
    catch {
        Write-Host "Errore durante la creazione della OU Utenti_User: $_"
    }
$childOUDN = "OU=Utenti_Admin,$parentOU_DN"

    try {
        New-ADOrganizationalUnit -Name "Utenti_Admin" -Path $parentOU_DN
        Write-Host "OU figlia Utenti_Admin creata con successo in '$parentOU'."
    }
    catch {
        Write-Host "Errore durante la creazione della OU Utenti_User: $_"
    }
$childOUDN = "OU=Computers_User,$parentOU_DN"

    try {
        New-ADOrganizationalUnit -Name "Computers_User" -Path $parentOU_DN
        Write-Host "OU figlia Computers_User creata con successo in '$parentOU'."
    }
    catch {
        Write-Host "Errore durante la creazione della OU Utenti_User: $_"
    }
$childOUDN = "OU=Computers_Admin,$parentOU_DN"

    try {
        New-ADOrganizationalUnit -Name "Computers_Admin" -Path $parentOU_DN
        Write-Host "OU figlia Computers_Admin creata con successo in '$parentOU'."
    }
    catch {
        Write-Host "Errore durante la creazione della OU Utenti_User: $_"
    }
}


# Ciclo principale per il menu
while ($true) {
    Show-Menu
   
   # Legge il tasto premuto senza bisogno di invio
    $tasto = [System.Console]::ReadKey($true).KeyChar
    
    
    switch ($tasto.ToString().ToUpper()) {
        '1' {
            Esegui-Comando1
        }
        '2' {
            Esegui-Comando2
        }
        '3' {
            Esegui-Comando3
        }
        'Q' {
            Write-Host "Uscita dal programma..."
            exit #Chiude la console e termina lo script
        }
        default {
            Write-Host "Scelta non valida, prova di nuovo."
        }
    }
    
    # Pausa per vedere il risultato del comando eseguito
    Start-Sleep -Seconds 10
}