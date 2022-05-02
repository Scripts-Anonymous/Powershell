<# NREN-Copy-File_Folder
  -----------------------------------------------------------------------------------------
    Author: 
	Jeff Allen
	Sr. Systems Administrator
	Version: 2021-06-18.1
    This script copies files/folders to all Windows objects in an OU. Needs to be run with a PAW or SERV.
#>

# Parameter to give file/folder
param(
	[parameter(Mandatory=$false)]
	[String]$Folder=(Read-Host "What file/folder would you like copied?")
)

# Figure out if user is an admin of a DAW or Server and set OU
$Groups=Get-ADUser -Identity "$env:USERNAME" -Properties MemberOf | Select -ExpandProperty MemberOf | Get-ADGroup | Select Name
Switch -Regex ($Groups){
    "PAWADMIN" {$OU="OU=*OU*,DC=*DOMAIN*"}
    "ServerAdmin" {$OU="OU=*OU*,DC=*DOMAIN*"}
}
If($OU -eq $null){
    Write-Host "You need to run this as a PAW or SERV" -ForegroundColor Red
    Pause
}
Else{
    # Get all Windows objects in that OU
    $Objects=(Get-ADComputer -Filter "OperatingSystem -like 'Windows*'" -SearchBase $OU -Properties Name | Select Name)
    foreach ($Object in $Objects){
	    Copy-Item -Recurse $Folder \\$Object\C$\adm\
    }
}
