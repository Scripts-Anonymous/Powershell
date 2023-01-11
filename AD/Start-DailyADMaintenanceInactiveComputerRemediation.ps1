<#
    .Synopsis
    This script will notify/disable/delete computer objects at 15/30/45 day increments.

    .Parameter OU
    Required parameter to target specific OU.

    .Parameter LocalOnly
    Useful if running the script from an account that doesn't have write priveledges to sysvol.

    .Parameter WhatIf
    Useful if running the script for testing purposes. Will NOT make any changes to objects. This will also skip notifying end users.

    .EXAMPLE
    PS> Start-DailyADMaintenanceInactiveComputerRemediation -OU NR
    Will look at computer objects in the OU and act on any notify/disable/delete actions. Files will be output to the local system and sysvol.

    .EXAMPLE
    PS> Start-DailyADMaintenanceInactiveComputerRemediation -OU NR -LocalOnly
    Will look at computer objects in the OU and act on any notify/disable/delete actions. Files will only be output to the local system.

    .EXAMPLE
    PS> Start-DailyADMaintenanceInactiveComputerRemediation -OU NR -LocalOnly -WhatIf
    Will look at computer objects in the OU and will NOT act on any notify/disable/delete actions. Files will only be output to the local system.
#>

#Requires -Version 5
#Requires -Modules ActiveDirectory
Import-Module ActiveDirectory

function Start-DailyADMaintenanceInactiveComputerRemediation {
    Param (
        [parameter(Mandatory=$true)]
        [ValidateSet("xx")]
        [String]$OU,
        [parameter(Mandatory=$false)]
        [Switch]$LocalOnly,
        [parameter(Mandatory=$false)]
        [Switch]$WhatIf
    )
   
    # Variables
    $Date = Get-Date -Format 'yyyyMMdd_HHmm'
    $LocalPath = "C:\Scripts\domain\AD\Reports"
    $SysvolPath = "\\domain.local\sysvol\domain.local\scripts\AD\Reports"
    $Domain = $null
    $Domain = 'domain.local'
    $SearchBase = $null
    $SiteTable=@{
        'xx'='myOU'
    }
    $Site = $SiteTable.$OU
    $SearchBase = "OU=$Site,DC=domain,DC=local"
    $DC = $null
    $DCList = $null
    $DCs = $null
    $func = $null
    $JobsOutput = $null
    $JobsOutput2 = $null
    $JobsOutput3 = $null
    $LastLogonData = $null
    $ComputersToBeDisabled = $null
    $ToBeDisabledReport = $null
    $ComputersToBeDeleted = $null
    $ToBeDeletedReport = $null
    $ComputersToBeNotified = $null
    $ToBeNotifiedReport = $null
    $To = $null
    [string[]]$To = @()
    $ADAdmins = $null
    $From = $null
    $Subject = $null
    $Body = $null
    $Priority = $null

    Start-Transcript -Path "C:\Scripts\domain\AD\Transcripts\$Date-$OU-DailyADMaintenanceInactiveComputer_Remediation.txt"

    # Creating Directory to Store AD Daily Maintenace Reports
    if ((Test-Path -Path $LocalPath) -eq $false){
        New-Item -ItemType Directory -Path $LocalPath
    }
    if ((Test-Path -Path $SysvolPath) -eq $false){
        New-Item -ItemType Directory -Path $SysvolPath
    }

    # Queries domain for a list of all DCs starting with "$OU" and "NR"
    Write-Host "Generating List of DCs to query for Computer lastlogon values..."
    $DC = Get-ADDomainController -Discover -DomainName $Domain | Select-Object -ExpandProperty Hostname
    $DCList = Get-ADDomainController -Filter * -Server $DC | Where-Object {$_.Name -like "$OU*" -or $_.Name -like "NR*"}
    $DCs = @()

    # Setup NR_T1As mail group for error catching
    $ADAdmins = Get-ADGroupMember -Identity 'AD-T1-Admins' -Server $domain | Select-Object -ExpandProperty SamaccountName | Get-ADUser -Properties Mail | Select-Object -Property Mail

    # Tests connection to local and NOC DCs
    $DCList | ForEach-Object {
        $CurrentDCRecord = $null
        $CurrentDCRecord = $_
        $CurrentDC = $null
        $CurrentDC = $_.HostName
        Write-Host "Testing connectivity to $CurrentDC..."
        $testResult = $null
        $testResult = Test-Connection -ComputerName $CurrentDC -Quiet
        if($testResult -eq $true){
            Write-Host "Connectivity test to $CurrentDC was successful.  Adding DC to list of DCs to be queried..." -ForegroundColor Green
            $DCs += $CurrentDCRecord
            }
        if($testResult -eq $false){
            Write-Host "Connectivity test to $CurrentDC was unsuccessful.  Not all DCs are reachable.  All DCs must be reachable to get accurate lastLogin data.  Exiting script..." -ForegroundColor Yellow
        }
    }
   
    # Function Definition for Jobs that will execute on all DCs in parallel for lastLogon data
    $func = {
        function QueryDC {
            param (
                [string]$CurrentDC,
                [string]$SB
            )        
            try {
                $Computers = $null
                $Computers = Get-ADComputer -Filter * -SearchBase $SB -Server $CurrentDC -Properties lastlogon,lastlogonTimeStamp,memberof,whenCreated,whenChanged,Description,OperatingSystem,mail |
                Select-Object Name,
                @{N='lastlogon';E={[datetime]::fromFileTime($_.'lastlogon')}},
                @{N='lastlogonTimeStamp';E={[datetime]::fromFileTime($_.'lastlogonTimeStamp')}},
                @{N='lastlogonDC';E={$CurrentDC}},
                @{N='memberof';E={$_.memberof -join ';'}},
                OperatingSystem,Enabled,Description,whenCreated,whenChanged,DistinguishedName,ObjectClass,ObjectGUID,SamAccountName,SID,userPrincipalName,mail |
                Sort-Object Name
                Write-Output $Computers
            }
            catch {
                $ErrorFound = $_
                Write-Output $ErrorFound
            }        
        }    
    }

    # Start querying all DCs in parallel for lastLogon data
    Write-Host "Querying all DCs in parallel for lastlogon info.  Please standby..."
    foreach ($item in $DCs){  
        Start-Sleep -Seconds 30
        Start-Job -ScriptBlock { param($one,$two) QueryDC -CurrentDC $one -SB $two } -ArgumentList $item.Hostname,$SearchBase -InitializationScript $func -Name $item.Hostname
    }
    Write-Host "Waiting for jobs to complete..."
    Get-Job | Wait-Job
    Write-Host "Jobs complete.  Continuing processing..."
    $JobsOutput = @()
    Get-Job | ForEach-Object {
        $_.Name
        $JobResults = $null
        $JobResults = Receive-Job $_ -Keep
        if ($null -eq $JobResults.Exception){
            Write-Host "Job $($_.Name) completed without error. Storing results..."
            $JobsOutput += $JobResults
        }
        else{
            Write-Host "Job $($_.Name) completed with the following error message:" -ForegroundColor Red
            $Jobresults.Exception
        }
    }
    Get-Job | Stop-Job
    Get-Job | Remove-Job -Force

    # Start generating reports of lastLogon data
    Write-Host "Generating report..."
    $JobsOutput2 = $JobsOutput | Sort-Object -Property Name,@{Expression = {$_.lastlogon}; Ascending = $false}
    $JobsOutput2 | Select-Object Name,Enabled,lastlogonDC,lastlogon,lastlogonTimeStamp,mail |
    Export-Csv -Path "$LocalPath\$Date-$OU-DailyADMaintenanceInactiveComputerRemediation_ALL.csv" -NoTypeInformation
    if ($LocalOnly -eq $false) {
        Copy-Item -Path "$LocalPath\$Date-$OU-DailyADMaintenanceInactiveComputerRemediation_ALL.csv" -Destination "$ExportPath\$OU-DailyADMaintenanceInactiveComputerRemediation_ALL.csv" -Force
    }
    $JobsOutput3 = $JobsOutput2 | Group-Object Name | ForEach-Object { $_.Group | Sort-Object lastlogon -Descending | Select-Object -First 1 }
    $LastLogonData = $JobsOutput3 | Select-Object Name,Enabled,lastlogonDC,@{N='Most_Recent_LastLogon';E={($_.lastlogon, $_.lastlogonTimeStamp | Measure-Object -Maximum).Maximum}},memberOf,Description,OperatingSystem,whenCreated,whenChanged,DistinguishedName,ObjectClass,ObjectGUID,SamAccountName,SID,userPrincipalName,mail
    $LastLogonData | Export-Csv -Path "$LocalPath\$Date-$OU-DailyADMaintenanceInactiveComputerRemediation.csv" -NoTypeInformation
    if ($LocalOnly -eq $false) {
        Copy-Item -Path "$LocalPath\$Date-$OU-DailyADMaintenanceInactiveComputerRemediation.csv" -Destination "$ExportPath\$OU-DailyADMaintenanceInactiveComputerRemediation.csv" -Force
    }
    Write-Host "Generating reports complete."

    <# ***IMPORTANT***:
    Everything up to this point has been dedicated to checking site and NOC DCs for the lastLogon for each computer.
    Then, for each computer, comparing the lastLogon time from site and NOC DCs, and using the most recent lastLogon to determine if a computer should be disabled and/or deleted.
    It compares all lastlogons from site and NOC DCs, takes the most recent, then compares that to the lastLogonTimeStamp, and then takes the most recent between those.
    The reason a final comparison beween lastLogon and lastLogonTimeStamp is done:
        In case a user has been at another site for over 30 days or more, and has been authenticating to non-local site or Non-NOC DCs, the script also does a comparision of the lastLogon to lastLogonTimeStamp as a backup.
        If the lastLogonTimStamp is more recent than the most recent LastLogon from site and NOC DCs, then the lastLogonTimeStamp will be used when determining if a computer will be disabled and/or deleted.
        LastLogonTimeStamp is replicated to all DCs in the domain every 9-14 days, so if a user is has not been authenticating to site or NOC DCs, we will not disable and/or delete thier computer in error.
    The most recent lastLogon data is stored in the $LastLogonData variable.
    Now that we have the computer mapped to its most recent lastLogon we can move onto using that data to determine if a computer needs to be disabled and/or deleted.
    #>

    # Disable computers that have not authenticated to AD in over 30 days
    $ComputersToBeDisabled = $LastLogonData |
    Where-Object -FilterScript {$_.memberof -notlike "*$OU-Exception-AccountDisable*"} |
    Where-Object -FilterScript {$_.Most_Recent_LastLogon -le (Get-Date).AddDays(-30)} |
    Where-Object -FilterScript {$_.whenCreated -le (Get-Date).AddDays(-30)} |
    Where-Object -FilterScript {$_.whenChanged -le (Get-Date).AddDays(-5)} |
    Where-Object -FilterScript {$_.Enabled -eq $true}
    Write-Host "Computer to be disabled" $ComputersToBeDisabled.Count
    $ToBeDisabledReport = @()
    $ComputersToBeDisabled | ForEach-Object {
        $myobj = $null
        $myobj = New-Object -TypeName PSObject
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'Name' -Value $_.Name
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'Result' -Value ''
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'EnabledStatusBeforeScript' -Value $_.Enabled
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'EnabledStatusAfterScript' -Value ''
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'Most_Recent_LastLogon' -Value $_.Most_Recent_LastLogon
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'OperatingSystem' -Value $_.operatingSystem
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'whenCreated' -Value $_.whenCreated
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'whenChanged' -Value $_.whenChanged
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'Description' -Value $_.Description
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'DistinguishedName' -Value $_.DistinguishedName
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'ObjectClass' -Value $_.ObjectClass
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'ObjectGUID' -Value $_.ObjectGUID
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'SamAccountName' -Value $_.SamAccountName
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'SID' -Value $_.SID
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'UserPrincipalName' -Value $_.UserPrincipalName
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'memberof' -Value $_.memberof
        if ($WhatIf -eq $false){
            try{
                Disable-ADAccount -Identity $_.samaccountname -Confirm:$false
                $myobj.Result = 'Disabled due to inactivity'
                $myobj.'EnabledStatusAfterScript' = $false
                }
            catch{
                $myobj.Result = "Error occurred when attempting to disable Computer account: $($_.Exception.Message)"
                $myobj.'EnabledStatusAfterScript' = $true
                }
            $ToBeDisabledReport += $myobj
        }
        else{
            try{
                $myobj.Result = "No changes have been made. Script was run in 'WhatIf' mode."
                $myobj.'EnabledStatusAfterScript' = $true
                }
            catch{
                $myobj.Result = "No changes have been made. Script was run in 'WhatIf' mode and an error occurred when attempting to disable Computer account: $($_.Exception.Message)"
                $myobj.'EnabledStatusAfterScript' = $true
                }
            $ToBeDisabledReport += $myobj
        }
    }
    $ToBeDisabledReport | Export-Csv -Path "$LocalPath\$Date-$OU-Computers-Disabled-due-to-30-days-of-inactivity.csv" -NoTypeInformation -Force
    if ($LocalOnly -eq $false) {
        Copy-Item -Path "$LocalPath\$Date-$OU-Computers-Disabled-due-to-30-days-of-inactivity.csv" -Destination "$ExportPath\$OU-Computers-Disabled-due-to-30-days-of-inactivity.csv" -Force
    }

    # Delete computers that have not authenticated to AD in over 45 days
    $ComputersToBeDeleted = $LastLogonData |
    Where-Object -FilterScript {$_.memberof -notlike "*$OU-Exception-AccountDelete*"} |
    Where-Object -FilterScript {$_.Most_Recent_LastLogon -le (Get-Date).AddDays(-45)} |
    Where-Object -FilterScript {$_.whenCreated -le (Get-Date).AddDays(-30)} |
    Where-Object -FilterScript {$_.whenChanged -le (Get-Date).AddDays(-5)}
    Write-Host "Computer to be deleted" $ComputersToBeDeleted.Count
    $ToBeDeletedReport = @()
    $ComputersToBeDeleted | ForEach-Object {
        $myobj = $null
        $myobj = New-Object -TypeName PSObject
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'Name' -Value $_.Name
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'Result' -Value ''
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'EnabledStatusBeforeScript' -Value $_.Enabled
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'EnabledStatusAfterScript' -Value ''
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'Most_Recent_LastLogon' -Value $_.Most_Recent_LastLogon
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'OperatingSystem' -Value $_.operatingSystem
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'whenCreated' -Value $_.whenCreated
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'whenChanged' -Value $_.whenChanged
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'Description' -Value $_.Description
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'DistinguishedName' -Value $_.DistinguishedName
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'ObjectClass' -Value $_.ObjectClass
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'ObjectGUID' -Value $_.ObjectGUID
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'SamAccountName' -Value $_.SamAccountName
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'SID' -Value $_.SID
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'UserPrincipalName' -Value $_.UserPrincipalName
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'memberof' -Value $_.memberof
        if ($WhatIf -eq $false){
            try {
                Remove-ADObject -Identity $_.DistinguishedName -Recursive -Confirm:$false
                $myobj.Result = 'Deleted due to inactivity'
                }
            catch {
                $myobj.Result = "Error occurred when attempting to delete Computer account: $($_.Exception.Message)"
                }
            $ToBeDeletedReport += $myobj
        }
        else {
            try {
                $myobj.Result = "No changes have been made. Script was run in 'WhatIf' mode."
                $myobj.'EnabledStatusAfterScript' = $true
                }
            catch {
                $myobj.Result = "No changes have been made. Script was run in 'WhatIf' mode and an error occurred when attempting to disable Computer account: $($_.Exception.Message)"
                $myobj.'EnabledStatusAfterScript' = $true
                }
            $ToBeDeletedReport += $myobj
        }
    }
    $ToBeDeletedReport | Export-Csv -Path "$LocalPath\$Date-$OU-Computers-Deleted-due-to-45-days-of-inactivity.csv" -NoTypeInformation -Force
    if ($LocalOnly -eq $false) {
        Copy-Item -Path "$LocalPath\$Date-$OU-Computers-Deleted-due-to-45-days-of-inactivity.csv" -Destination "$ExportPath\$OU-Computers-Deleted-due-to-45-days-of-inactivity.csv" -Force
    }

    # Notify computer owner that computer will be disabled in 15 days or less
    $ComputersToBeNotified = $LastLogonData |
    Where-Object -FilterScript {$_.memberof -notlike "*$OU-Exception-AccountDisable*"} |
    Where-Object -FilterScript {$_.memberof -notlike "*$OU-Exception-AccountDelete*"} |
    Where-Object -FilterScript {$_.Most_Recent_LastLogon -le (Get-Date).AddDays(-15)} |
    Where-Object -FilterScript {$_.Most_Recent_LastLogon -ge (Get-Date).AddDays(-29)} |
    Where-Object -FilterScript {$_.Enabled -eq $true} |
    Where-Object -FilterScript {$null -ne $_.mail}
    Write-Host "Computer to be Notified" $ComputersToBeNotified.Count
    $ToBeNotifiedReport = @()
    $CurrentDate1 = Get-Date
    $ComputersToBeNotified | ForEach-Object {
        $Most_Recent_LastLogon = $_.Most_Recent_LastLogon
        $DateToBeDisabled = $Most_Recent_LastLogon.AddDays(30)
        $DateToBeDisabledEmailFormat = $DateToBeDisabled.ToShortDateString()
        $DaysLeftTillDisable = ($DateToBeDisabled - $CurrentDate1).Days
        $DaysSinceAuthentication = ($CurrentDate1 - $Most_Recent_LastLogon).Days
        $myobj = $null
        $myobj = New-Object -TypeName PSObject
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'Name' -Value $_.Name
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'Result' -Value ''
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'Status' -Value 'Notified by email of account inactivity'
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'Most_Recent_LastLogon' -Value $_.Most_Recent_LastLogon
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'DateToBeDisabled' -Value $DateToBeDisabled
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'DaysLeftTillDisable' -Value $DaysLeftTillDisable
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'whenCreated' -Value $_.whenCreated
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'whenChanged' -Value $_.whenChanged
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'Description' -Value $_.Description
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'DistinguishedName' -Value $_.DistinguishedName
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'ObjectClass' -Value $_.ObjectClass
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'ObjectGUID' -Value $_.ObjectGUID
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'SamAccountName' -Value $_.SamAccountName
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'SID' -Value $_.SID
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'UserPrincipalName' -Value $_.UserPrincipalName
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'memberof' -Value $_.memberof
        Add-Member -InputObject $myobj -MemberType NoteProperty -Name 'mail' -Value $_.mail
        $ToBeNotifiedReport += $myobj
    }
    $ToBeNotifiedReport | Export-Csv -Path "$LocalPath\$Date-$OU-Computers-Notified-due-to-15-days-of-inactivity.csv" -NoTypeInformation -Force
    if ($LocalOnly -eq $false) {
        Copy-Item -Path "$LocalPath\$Date-$OU-Computers-Notified-due-to-15-days-of-inactivity.csv" -Destination "$ExportPath\$OU-Computers-Notified-due-to-15-days-of-inactivity.csv" -Force
    }
    Stop-Transcript
}