<#
	.NOTES
	Name		: Cleanup-Priv-Groups.ps1
	Author		: Mike Cress
	Created		: 2/4/2022
	Modified	: 
    .DESCRIPTION
	Checks all defined AD groups and removes all members who are not in a respectively defined Exception group.
	.PARAMETER
	.EXAMPLE
    CleanupPrivGroups.ps1
#>

# Sets the script log location and begins transcript logging
$scriptLog = $MyInvocation.MyCommand.Path -replace '\.ps1$', '.log'
Start-Transcript -Path $scriptLog -Append

# Function for determing the exact date and time
function Get-TimeStamp {
    return (Get-Date).ToString("yyyyMMdd-HHmmss")
}

Write-Output "$(Get-TimeStamp) Begin logging"

function CleanupPrivGroups() {

    Param (
    [Parameter(Mandatory = $true)] [string] $privGroup,
    [Parameter(Mandatory = $true)] [string] $exceptionGroup
    )

    # Gets members of groups
    $privGroupMembers = Get-ADGroupMember -Identity $privGroup
    $exceptionGroupMembers = Get-ADGroupMember -Identity $exceptionGroup

    # Verify groups exist
    if (@(Get-ADGroup -Identity $privGroup -ErrorAction SilentlyContinue).Count) {
        #Write-Host "$(Get-TimeStamp) $privGroup exists."        
    } else {
        Write-Host "$(Get-TimeStamp) $privGroup does not exist. Skipping cleanup of $privGroup"
        break
    }
    if (@(Get-ADGroup -Identity $exceptionGroup -ErrorAction SilentlyContinue).Count) {
        #Write-Host "$(Get-TimeStamp) $exceptionGroup exists."        
    } else {
        Write-Host "$(Get-TimeStamp) $exceptionGroup does not exist. Skipping cleanup of $privGroup"
        break
    }

    # Determine which users in privGroup are not in the exceptionGroup
    $usersToRemove = $privGroupMembers.samaccountname | where {$exceptionGroupMembers.samaccountname -notcontains $_}
    
    # Remove unapproved users
    foreach ($user in $usersToRemove) {
        Write-Host "$(Get-TimeStamp) $user not in $exceptionGroup. Removing from $privGroup."
        Remove-ADGroupMember -Identity $privGroup -Members $user -Confirm:$False
    }
}

#CleanupPrivGroups -privGroup "PRIVILEGED-GROUP-HERE" -exceptionGroup "EXCEPTION-GROUP-HERE"

# Stops transcript logging
Write-Output "$(Get-TimeStamp) End logging"
Stop-Transcript