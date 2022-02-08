<#
	.NOTES
	Name		: Prevent-delegation-of-priv-accounts.ps1
	Author		: Mike Cress
	Created		: 2/8/2022
	Modified	: 
    .DESCRIPTION
	Ensures "Account is sensitive and cannot be delegated" is enforced on all privileged accounts to comply with AD STIG V-243470
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

# Identify all accounts that should not be delegated
$privUsers = Get-ADUser -Filter *

# Identify those accounts that ARE delegated
$delegatedUsers = $privUsers | Get-ADUser -Properties AccountNotDelegated | 
Where-Object {
  -not $_.AccountNotDelegated -and
  $_.objectClass -eq "user"
}

# Remove the delegation
foreach ( $user in $delegatedUsers ) {
    Write-Output "$(Get-TimeStamp) Removing delegation for $user.samaccountname"
    Set-ADUser $user -AccountNotDelegated $true
}

# Stops transcript logging
Write-Output "$(Get-TimeStamp) End logging"
Stop-Transcript