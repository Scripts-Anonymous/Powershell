<#
    .NAME
    VMware-SCG_VirtualMachine.ps1

    .AUTHOR
    Jeff Allen
    im@jeffreyallen.tech

    .SYNOPSIS
    

    .SYNTAX


    .DESCRIPTION
    

    .OUTPUTS
    

    .RELATED LINKS
    GITHUB link:

  
    .REMARKS


    .EXAMPLE
    PS> .\

    .EXAMPLE
    PS> .\

#>

# Variables
$vcenter=*FQDN*
$credentials=Get-Credential


# Check
Get-VM | Get-AdvancedSetting isolation.tools.copy.disable
Get-VM | Get-AdvancedSetting isolation.tools.paste.disable
Get-VM | Get-AdvancedSetting isolation.tools.diskShrink.disable
Get-VM | Get-AdvancedSetting isolation.tools.diskWiper.disable
Get-VM | Get-AdvancedSetting mks.enable3d
Get-VM | Get-AdvancedSetting RemoteDisplay.maxConnections
Get-VM | Get-AdvancedSetting tools.setInfo.sizeLimit
Get-VM | Get-AdvancedSetting log.keepOld
Get-VM | Get-AdvancedSetting log.rotateSize
Get-VM | Get-AdvancedSetting -Name "pciPassthru*.present" | Select Entity, Name, Value
Get-VM | Get-AdvancedSetting tools.guestlib.enableHostInfo
Get-VM | Get-AdvancedSetting sched.mem.pshare.salt
Get-VM | Get-AdvancedSetting -Name "ethernet*.filter*.name*" | Select Entity, Name, Value
Get-VM | Get-AdvancedSetting tools.guest.desktop.autolock

TRUE	TRUE
TRUE	TRUE
TRUE	TRUE
TRUE	TRUE
FALSE	FALSE
1	40
1048576	1048576
10	6
2048000	0
Site-Specific	FALSE
FALSE	FALSE
Site-Specific	Null
Null unless using dvfilter	Null
Required	Opportunistic
TRUE	FALSE

# Set
Get-VM | Get-AdvancedSetting isolation.tools.copy.disable | Set-AdvancedSetting -Value TRUE
Get-VM | Get-AdvancedSetting isolation.tools.paste.disable | Set-AdvancedSetting -Value TRUE
Get-VM | Get-AdvancedSetting isolation.tools.diskShrink.disable | Set-AdvancedSetting -Value TRUE
Get-VM | Get-AdvancedSetting isolation.tools.diskWiper.disable | Set-AdvancedSetting -Value TRUE
Get-VM | Get-AdvancedSetting mks.enable3d | Set-AdvancedSetting -Value FALSE
Get-VM | Get-AdvancedSetting RemoteDisplay.maxConnections | Set-AdvancedSetting -Value 1
Get-VM | Get-AdvancedSetting tools.setInfo.sizeLimit | Set-AdvancedSetting -Value 1048576
Get-VM | Get-AdvancedSetting log.keepOld | Set-AdvancedSetting -Value 10
Get-VM | Get-AdvancedSetting log.rotateSize | Set-AdvancedSetting -Value 2048000
Get-VM | Get-AdvancedSetting tools.guestlib.enableHostInfo | Set-AdvancedSetting -Value FALSE
Site-Specific. See other entries here for examples.
Get-VM | Get-AdvancedSetting tools.guest.desktop.autolock | Set-AdvancedSetting -Value TRUE