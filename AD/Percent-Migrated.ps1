<# Percent-Migrated
    Author: 
    Jeff Allen
    https://github.com/Scripts-Anonymous/Powershell/tree/main/AD
#>
<#
.SYNOPSIS
    Gets the percentage of computer objects that have been migrated from a legacy domain to the new domain.

.DESCRIPTION
    Script was original written by a Microsoft Employee. I heavily modified it to fit our domain. If checking migration status of more than one domain, you will need to modify the "DomainTable" to add additional domains.

.PARAMETER Output
    -Output <string>
        Required?                    True

.PARAMETER LegacyDomain
    -LegacyDomain <string>
        Required?                    True

.OUTPUTS
    Will output a .txt file with the name of the domain you're checking the migration status on.

.EXAMPLE
    PS> .\Pecent-Migrated.ps1 -Output C:\adm\ -LegacyDomain
#>

#Requires -Modules ActiveDirectory
param(
    [parameter(Mandatory=$True)]
    [String]$Output,
    [parameter(Mandatory=$True)]
    [String][ValidateSet("LD")]$LegacyDomain
)

#region Script
#region PT1
#This section gets all computer objects from the legacy domain
$DateLong = Get-Date
$DateShort = Get-Date -Format yyyyMMdd
$DomainTable=@{
    'LD'='contoso.com'
}
$Domain=($DomainTable.$LegacyDomain)
$PDC=Get-ADDomainController -Discover -Domain $Domain -Service GlobalCatalog
[string]$DNAME=($PDC.Hostname)
Try {
    Test-NetConnection $DNAME -port 389 -ErrorAction Stop | Out-Null
}
Catch {
    Write-Host "An error occurred:" -ForegroundColor Red
    Write-Host $_ -ForegroundColor Red
    Exit
}
Write-Host "Getting computer objects" -ForegroundColor DarkGreen
$AllComObjects = Get-ADComputer -Server $DNAME -Filter * -Properties CN, DistinguishedName, DNSHostName, Enabled, OperatingSystem, lastLogon -Verbose
#$AllComObjects | Export-Csv -Path "$Output\$DateShort-$DName.csv" -Verbose -NoClobber -NoTypeInformation
#endregion

#region PT2
#This section compares items from Get-LegacyComputerObjects to the objects in the NREN Domain
$PDC=Resolve-DnsName _ldap._tcp.dc._msdcs.contoso.com
$DC=($PDC.PrimaryServer)
$OUTable=@{
    'WC'='OU'
}
$OU=($OUTable.$LegacyDomain)
$OUNoSpace=($OU -replace '\s+')
If(Get-ADOrganizationalUnit -Filter {name -like $OU} -Server $DC){
    Write-Host "$OU Found" -ForegroundColor Green
    $NewOU = (Get-ADOrganizationalUnit -Filter {name -like $OU} -Server $DC).distinguishedname
    Write-Host "Searching $NewOU" -ForegroundColor Green
    $NewList = Get-ADComputer -SearchBase "$NewOU" -Filter * -Server $DC -Verbose
    Write-Host 'Found '$NewList.count' objects' -ForegroundColor Green
    #$NewList | Export-Csv "$Output\$DateShort-NREN-$OUNoSpace.csv" -Force -NoClobber -NoTypeInformation -Verbose
    Write-Host "Comparing Computer Lists" -ForegroundColor Green
    $DifPercent = ($NewList.Count/$AllComObjects.count).tostring("P")
    Write-Host "You are $DifPercent migrated" -ForegroundColor Green
    #Write-Host "Your Deltas have been exported to $Output\$DateShort-Deltas.csv"
    #Compare-Object -ReferenceObject $LegacyList -DifferenceObject $NewList | Export-Csv "$Output\$OUNoSpace-Deltas.csv" -NoTypeInformation -Force
    Add-content "$Output\$OUNoSpace.txt" -Value "$DateLong - $DifPercent"
}
#endregion
#endregion
