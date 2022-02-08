<#
	.NOTES
	Name		: Disable-Inactive-Users.ps1
	Author		: Mike Cress
	Created		: 12/3/21
	Modified	: 1/25/22 Added script formatting and logging
    .DESCRIPTION
	Disable accounts after 180 days inactivity
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

function Disable-Inactive-Users {

    param (
        [String]$AuditOnly
    )

    # Sets number of days for inactivity check
    Write-Output "$(Get-TimeStamp) Setting inactive check to 180 days"
    $days = 180
    $time = (Get-Date).Adddays(-($days))

    # Gets inactive users
    Write-Output "$(Get-TimeStamp) Getting inactive users"
    $inactiveUsers = Get-ADUser -Filter {Enabled -eq 'True' -and LastLogonTimeStamp -lt $time} -Properties Name,samaccountname,LastLogonTimeStamp,LastLogonDate

    # Check if just auditing
    If ($AuditOnly -eq "True") {
        Write-Output "$(Get-TimeStamp) Audit Mode True"
        Write-Output " Following are inactive for over $days days"
        $inactiveUsers | select name,samaccountname,lastlogondate
    } else {
        Write-Output "$(Get-TimeStamp) Audit Mode False"
        Foreach ($user in $inactiveUsers) {
            Write-Output "$(Get-TimeStamp) Disabling $user"
            Disable-ADAccount -Identity $user.samaccountname
        }
    }
}

Disable-Inactive-Users -AuditOnly False

# Stops transcript logging
Write-Output "$(Get-TimeStamp) End logging"
Stop-Transcript
