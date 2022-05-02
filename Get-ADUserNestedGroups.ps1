<# Get-ADUserNestedGroups
  -----------------------------------------------------------------------------------------
    Author: 
	Jeff Allen
	Sr. Systems Administrator
	Version: 2022.03.01
    This script will find all groups a user is part of (including nested groups).
#>
Param(
    [parameter(Mandatory=$true)]
    [String]$User
)
$DN=(Get-ADUser -Identity $User).DistinguishedName
$Groups = Get-ADGroup -LDAPFilter "(member:1.2.840.113556.1.4.1941:=$DN)"
$Groups | Select-Object Name | Sort-Object -Property Name;