<# NREN_Get-OU-ACLs
  -----------------------------------------------------------------------------------------
    Author: 
	Jeff Allen
	Sr. Systems Administrator
	Version: 2021-06-18.2
        TODO: Add the ability to get extended permissions (Check Parkers Script ".\Parker-Scripts\ACE-Permissions")
#>

<# Parameters
    You can use the following parameters at the command line to skip inputing them.
    -OUPath: The DN of the OU Path you want the permissions of. Please use quotes if the DN has spaces.
    -File: Output path/filename where you want the file output too. Please use an extension.
    -Inherited: If you would like to include Inherited permissions use this switch. By default it will not include Inherited permissions.
#>
param(
	[parameter(Mandatory=$false)]
	[String]$SearchBase = $(Read-Host "Please input the OU Path you want to export. Example: OU=*OU*,DC=*DOMAIN*"),
	[parameter(Mandatory=$false)]
	[String]$File = $(Read-Host "Please input the path and name of the file. Example: .\export.csv or C:\adm\export.csv"),
	[parameter(Mandatory=$false)]
	[Switch]$Inherited
)
# Import AD Module
Import-Module ActiveDirectory

# Set file headers.
"Path;ID;Rights;Type" | Out-File $File

# Get OUs
$OUs=Get-ADOrganizationalUnit -Filter * -SearchBase $SearchBase
# Creating the Array
$Result=@()
# Get ACLs of each OU
ForEach($OU in $OUs){
	$OUPath="AD:\" + $OU.DistinguishedName
	$ACLs=(Get-ACL -Path $OUPath).Access
	ForEach($ACL in $ACLs){
		# Export non-inherited ACL's
		If(($Inherited -eq $False) -and ($ACL.IsInherited -eq $False)){
			$Properties=@{
				ACL=$ACL
				OU=$OU.DistinguishedName
			}
		}
        # Export inherited ACL's
        Elseif($Inherited -eq $True){
    		$Properties=@{
				ACL=$ACL
				OU=$OU.DistinguishedName
			}
        }
		$Result += New-Object psobject -Property $Properties
        # Set Properties to null so permissions aren't duplicated.
        $Properties=$null
	}
}
ForEach($Item in $Result){
    If($Item -NotLike $null){
	    $Output=$Item.OU + ";" + $Item.ACL.IdentityReference + ";" + $Item.ACL.ActiveDirectoryRights + ";" + $Item.ACL.AccessControlType
	    $Output | Out-File $File -Append
    }
}
