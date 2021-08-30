<#
    .NAME
    Import-DemoDomain

    .AUTHOR
    Jeff Allen

    .SYNOPSIS
    This script will create a basic Tier 0-2 Domain (in a single domain)

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

<# Structure
Enterprise
    Core-Groups
        Service-Accounts
        T1-Admins
        T1-Auditors
    Enterprise-Core
        Groups
            General
            T1-Groups
            T2-Groups
            T4-Groups
        Isolation (blocked inheritance)
        Servers
            Linux
        Users
            Disabled
            General
            Service-Accounts
            T1-Admins
            T2-Admins
            T4-Admins
        Workstations
            General
            T1-DAWs
            T2-DAWs
        VDI
            Groups
                General
                T1-Groups
            Workstations
                General
                T1-DAWs
                T2-DAWs

Enterprised_Privileged
    Core-Groups
        Service-Accounts
        Silver-Admins
        Silver-Auditors
    Privileged-Core
        Groups
            T0-Groups
        Isolation (blocked inheritance)
        Servers
            Linux
        Users
            Service-Accounts
            T0-Admins
        Workstations
            T0-DAWs
        VDI
            Groups
                T0-Groups
            Workstations
                T0-DAWs

Template_Enterprise
    Core-Groups
        Service-Accounts
        T1-Admins
        T1-Auditors
    Enterprise-Core
        Groups
            General
            T1-Groups
            T2-Groups
            T4-Groups
        Isolation (blocked inheritance)
        Servers
            Linux
        Users
            Disabled
            General
            Service-Accounts
            T1-Admins
            T2-Admins
            T4-Admins
        Workstations
            General
            T1-DAWs
            T2-DAWs
        VDI
            Groups
                General
                T1-Groups
            Workstations
                General
                T1-DAWs
                T2-DAWs

Template_Privileged
    Core-Groups
        Service-Accounts
        Silver-Admins
        Silver-Auditors
    Privileged-Core
        Groups
            T0-Groups
        Isolation (blocked inheritance)
        Servers
            Linux
        Users
            Service-Accounts
            T0-Admins
        Workstations
            T0-DAWs
        VDI
            Groups
                T0-Groups
            Workstations
                T0-DAWs

Template_SiteName
    Core-SITE
        Groups
            T1-Groups
            T2-Groups
            T4-Groups
        Isolation
        Servers
            Pre-Production
            Production
            Test
        Users
            Disabled
            General
            Service-Accounts
            T1-Admins
            T2-Admins
            T4-Admins
        VDI
            Groups
                General
                T1-Groups
                T2-Groups
            Workstations
                General
                T1-DAWs
                T2-DAWs
        Workstations
            General
            T1-DAWs
            T2-DAWs
    Lab
        Approved-Lab
            Lab-n
                Lab-DAWs
                Lab-Groups
                Lab-Servers
                Lab-Workstations
            T3-Admins
            T3-Auditors
            T3-Groups

#>