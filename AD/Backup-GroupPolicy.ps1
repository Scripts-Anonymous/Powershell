# SCRIPT NAME   Backup-GroupPolicy.ps1
# DESCRIPTION   Backs up all GPOs with friendly name folders
# CREATED ON    1/18/22
# CREATED BY    Mike Cress
# NOTES         Original script by Mike Kanakos https://github.com/compwiz32/PowerShell


function Backup-GroupPolicy {
<#
    .SYNOPSIS
    Backs up all existing Group Policies to a folder
    .DESCRIPTION
    Backs up all Group Policies to a folder named after the current date. Each group policy is saved in
    its own sub folder. The folder name will be the name of the Group Policy.
    Folder Name Example:
    --------------------
    C:\GPBackup\2018-12-21\Default Domain Policy
    .PARAMETER Path
    Specifies the path where the backups will be saved. The path can be a local folder or a network based folder.
    This is a required parameter. Do not end the path with a trailing slash. A slash at the end will cause an error!
    Correct format:
    c:\backups or \\server\share
    Incorrect Format:
    c:\Backups\ or \\server\share\
    .PARAMETER Domain
    Specifies the domain to look for Group Policies. This is auto populated with the domain info from the PC running
    the cmdlet.
    .PARAMETER Server
    Specifies the Domain Controller to query for group Policies to backup
    .EXAMPLE
    Backup-GroupPolicy -path C:\Backup
    Description:
    This example creates a backup of the GPO's and saves them to the c:\backup folder.
    Since no server was specified, the code will search for the nearest Domain Controller.
    .EXAMPLE
    Backup-GroupPolicy -path C:\Backup -Domain nwtraders.local -Server DC01
    Description:
    This example creates a backup of GPO's in the nwtraders.local domain to the C:\Backup folder.
    The backups will be pulled from the DC named DC01.
    .NOTES
    Name       : Backup-GroupPolicy.ps1
    Author     : Mike Kanakos
    https://github.com/compwiz32/PowerShell
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [Parameter(Mandatory=$True,Position=0)]
    [string]
    $Path,
    [Parameter()]
    [string]
    $Domain = (Get-WmiObject Win32_ComputerSystem).Domain,
    [Parameter()]
    [string]
    $Server
    )
    begin {
        # Get current GPO information
        $GPOInfo = Get-GPO -All -Domain $domain -Server $Server
        #Create a date-based folder to save backup of group policies
        $Date = Get-Date -UFormat "%Y%m%d-%H%M%S"
        $UpdatedPath = "$path\GpoBackup-$date"
        New-item $UpdatedPath -ItemType directory | Out-Null
        Write-Host "GPO's will be backed up to $UpdatedPath" -backgroundcolor white -foregroundColor red
    } #end of begin block
    process {
        ForEach ($GPO in $GPOInfo) {
            Write-Host "Backing up GPO named: " -foregroundColor Green -nonewline
            Write-Host $GPO.Displayname -foregroundColor White
            #Assign temp variables for various parts of GPO data
            $BackupInfo = Backup-GPO -Name $GPO.DisplayName -Domain $Domain -path $UpdatedPath -Server $Server
            $GpoBackupID = $BackupInfo.ID.Guid
            $GpoGuid = $BackupInfo.GPOID.Guid
            $GpoName = $BackupInfo.DisplayName
            $CurrentFolderName = $UpdatedPath + "\" + "{"+ $GpoBackupID + "}"
            $NewFolderName = $UpdatedPath + "\" + $GPOName + "___" + "{"+ $GpoBackupID + "}"
            $ConsoleOutput = $GPOName + "___" + "{"+ $GpoBackupID + "}"
            #Rename the newly created GPO backup subfolder from its GPO ID to the GPO Displayname + GUID
            rename-item $CurrentFolderName -newname $NewFolderName
        } #End ForEach loop

        # Zipping folder
        Write-Output "$(Get-TimeStamp) Zipping folder to archive $UpdatedPath.zip"
        Compress-Archive -Path $UpdatedPath -DestinationPath "$UpdatedPath.zip"

        # Removing non-zipped folder
        Write-Output "$(Get-TimeStamp) Deleting non-zipped folder $UpdatedPath"
        Remove-Item $UpdatedPath -Recurse -Force

    } #End of process block
    end {
    } #End of End block
} #End of function

# Sets the script log location and begins transcript logging
$scriptLog = $MyInvocation.MyCommand.Path -replace '\.ps1$', '.log'
Start-Transcript -Path $scriptLog -Append
           
# Function for determing the exact date and time
function Get-TimeStamp {
    return (Get-Date).ToString("yyyyMMdd-HHmmss")
}
Write-Output "$(Get-TimeStamp) Begin logging"

Backup-GroupPolicy -Path c:\scripts\Exports\GPO-Backups -Domain <domain.local> -Server <dc>

Write-Output "$(Get-TimeStamp) End logging"
Stop-Transcript