<# Convert-IPv4toIPv6.psm1
  -----------------------------------------------------------------------------------------
    Author: 
	Jeff Allen
	Systems Administrator
    Version: 2022-05-02

    .Synopsis
    Convert an IPv4 address to IPv6.

    .PARAMETER InterfaceAlias
    Please use only "InterfaceAlias" or "InterfaceIndex" to target the interface you want.

    .PARAMETER InterfaceIndex
    Please use only "InterfaceAlias" or "InterfaceIndex" to target the interface you want.
    
    .PARAMETER IPAddress
    If you just wish to type an IP, use this parameter.

    .EXAMPLE
    Convert-IPv4toIPv6 -InterfaceAlias "Ethernet0"

    .EXAMPLE
    Convert-IPv4toIPv6 -InterfaceIndex "14"

    .EXAMPLE
    Convert-IPv4toIPv6 -IPAddress "192.168.1.1"

#>

function Convert-IPv4toIPv6 {
    param (
        [parameter(Mandatory=$false)]
        [string]$InterfaceAlias,
        [parameter(Mandatory=$false)]
        [string]$InterfaceIndex,
        [parameter(Mandatory=$false)]
        [string]$IPaddress
    )
    if($InterfaceIndex){
        $ipv4Interface=Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceIndex -like $InterfaceIndex}
        $ipv4address=($ipv4Interface.IPAddress).split(".")
        Write-Host "InterfaceIndex"
        Write-Host "If using this script with an IPv4 Address assigned by DHCP, this script may not work correctly."
        $InterfaceIndex=$null
    }
    elseif($InterfaceAlias){
        $ipv4Interface=Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -like $InterfaceAlias}
        $ipv4address=($ipv4Interface.IPAddress).split(".")
        Write-Host "InterfaceAlias"
        Write-Host "If using this script with an IPv4 Address assigned by DHCP, this script may not work correctly."
        $InterfaceAlias=$null
    }
    elseif($IPAddress){
        $ipv4address=$IPaddress.split(".")
        Write-Host "IPAddress"
        $IPaddress=$null
    }
    else{
        Write-Host "Please read documentation and use a parameter (-IPAddress, -InterfaceIndex, -InterfaceAlias)."
    }
    $ipv6prefix="fc00::"
    $ipv6p5=('{0:X}' -f [int]$ipv4address[0])
    if($ipv6p5.length -eq "1"){
        $ipv6p5="0"+$ipv6p5
    }
    $ipv6p6=('{0:X}' -f [int]$ipv4address[1])
    if($ipv6p6.length -eq "1"){
        $ipv6p6="0"+$ipv6p6
    }
    $ipv6p7=('{0:X}' -f [int]$ipv4address[2])
    if($ipv6p7.length -eq "1"){
        $ipv6p7="0"+$ipv6p7
    }
    $ipv6p8=('{0:X}' -f [int]$ipv4address[3])
    if($ipv6p8.length -eq "1"){
        $ipv6p8="0"+$ipv6p8
    }
    $ipv6="$ipv6prefix"+"$ipv6p5"+"$ipv6p6"+":"+"$ipv6p7"+"$ipv6p8"
    Write-Host $ipv6
}