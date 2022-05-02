# DeleteWinBackups.ps1
# Deletes all backups except the most recent 60 versions
# Created on 1/18/22
# Created by Mike Cress

# Sets the script log location and begins transcript logging
$scriptLog = $MyInvocation.MyCommand.Path -replace '\.ps1$', '.log'
Start-Transcript -Path $scriptLog -Append

# Function for determing the exact date and time
function Get-TimeStamp {
    return (Get-Date).ToString("yyyyMMdd-HHmmss")
}

# Set the number of backup versions to keep
$keepVersions = 60
Write-Output "$(Get-TimeStamp) Setting KeepVersions variable to $keepVersions"

# Delete backups
Write-Output "$(Get-TimeStamp) Deleting backups"
wbadmin delete backup -keepversions:$keepVersions

# Stops transcript logging
Write-Output "$(Get-TimeStamp) End logging"
Stop-Transcript
