<#
Copyright (c) 2018-2021 VMware, Inc.  All rights reserved

The BSD-2 license (the "License") set forth below applies to all parts of the Desired State Configuration Resources for VMware project.  You may not use this file except in compliance with the License.

BSD-2 License

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#>

Param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Server,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $User,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Password,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $VMHostName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ScsiLunCanonicalName
)

$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, (ConvertTo-SecureString -String $Password -AsPlainText -Force)

$script:configurationData = @{
    AllNodes = @(
        @{
            NodeName = 'localhost'
            PSDscAllowPlainTextPassword = $true
            Server = $Server
            Credential = $Credential
            VMHostName = $VMHostName
            ScsiLunCanonicalName = $ScsiLunCanonicalName
        }
    )
}

<#
.DESCRIPTION

Modifies the configuration of the specified SCSI device by changing the Multipath policy to 'RoundRobin', the maximum number of I/O blocks to be issued on a given path
to '2048', the maximum number of I/O requests to be issued on a given path to '50'. The SCSI disk is marked as 'local' and 'SSD'.
#>
Configuration VMHostScsiLun_ModifyVMHostScsiLunConfigurationWithRoundRobinMultipathPolicy_Config {
    Import-DscResource -ModuleName VMware.vSphereDSC

    Node $AllNodes.NodeName {
        VMHostScsiLun VMHostScsiLun {
            Server = $AllNodes.Server
            Credential = $AllNodes.Credential
            VMHostName = $AllNodes.VMHostName
            CanonicalName = $AllNodes.ScsiLunCanonicalName
            MultipathPolicy = 'RoundRobin'
            BlocksToSwitchPath = 2048
            CommandsToSwitchPath = 50
            IsLocal = $true
            IsSsd = $true
        }
    }
}

VMHostScsiLun_ModifyVMHostScsiLunConfigurationWithRoundRobinMultipathPolicy_Config -ConfigurationData $script:configurationData
