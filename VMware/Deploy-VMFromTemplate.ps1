<#
    .NAME


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
#region 
#Variables
$VIServer=
$OSCustomization=
$ServerName=
$DomainCredentials=(Get-Credential)
$Domain=
$AdminCredentials=(Read-Host -AsSecureString)


#endregion

#Requires -Modules VMware.PowerCLI
Import-Module VMware.PowerCLI





New-OSCustomizationSpec -OSCustomizationSpec "$OSCustomization" -ChangeSid -AdminPassword $AdminCredentials -Domain $Domain -TimeZone 035 -DomainCredentials (Get-Credential) -AutoLogonCount 1