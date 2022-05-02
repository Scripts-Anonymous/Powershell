<#
	.NOTES
	Name		: Restrict-PreWindows2000.ps1
	Author		: Mike Cress
	Created		: 2/8/2022
	Modified	: 
    .DESCRIPTION
	Ensures compliance with AD STIG V-243486 by removing 'ANONYMOUS LOGON' and 'Everyone' from 'Pre-Windows 2000 Compatible Access group'
	.PARAMETER
	.EXAMPLE
#>

# Sets the script log location and begins transcript logging
$scriptLog = $MyInvocation.MyCommand.Path -replace '\.ps1$', '.log'
Start-Transcript -Path $scriptLog -Append

# Function for determing the exact date and time
function Get-TimeStamp {
    return (Get-Date).ToString("yyyyMMdd-HHmmss")
}

Write-Output "$(Get-TimeStamp) Begin logging"

# Get group members 
$groupMembers = net localgroup "Pre-Windows 2000 Compatible Access"

# Check to see if group contains either offending identities
if ( $groupMembers -contains "NT AUTHORITY\ANONYMOUS LOGON" -or $groupMembers -contains "Everyone"){
    
    # Check if ANONYMOUS LOGON present adn then remove
    if ( $groupMembers -contains "NT AUTHORITY\ANONYMOUS LOGON") {
        Write-Output "$(Get-TimeStamp) Removing ANONYMOUS LOGON identity from Pre-Windows 2000 Compatible Access"
        net localgroup "Pre-Windows 2000 Compatible Access" "nt authority\anonymous logon" /delete
    }
    
    # Check if Everyone present adn then remove
    if ( $groupMembers -contains "Everyone" ) {
        Write-Output "$(Get-TimeStamp) Removing Everyone identity from Pre-Windows 2000 Compatible Access"
        net localgroup "Pre-Windows 2000 Compatible Access" "nt authority\everyone" /delete
    }
}

else {
    Write-Output "$(Get-TimeStamp) No restricted identifies present. Compliance with V-243486 confirmed."
}

# Stops transcript logging
Write-Output "$(Get-TimeStamp) End logging"
Stop-Transcript