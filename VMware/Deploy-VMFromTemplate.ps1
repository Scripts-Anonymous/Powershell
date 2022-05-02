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
# VMware Variables
$VIServer=
$VI_Cluster=
$VI_VMTemplate=
$VI_CustomizationSpec=
$VI_Location=
$VI_Datastore=
$VI_VMStorageFormat=
$VI_NetworkName=
# VM Variables
$VM_Hostname=
$VM_Memory=
$VM_CPU=
$VM_DiskCapacity=
$VM_IP=
$VM_IP_Subnet=
$VM_IP_GW=
$VM_IP_DNS=
$VM_DomainCredential=(Get-Credential)
$VM_Domain=
$VM_AdminCredential=(Read-Host -AsSecureString)
#endregion

#Requires -Modules VMware.PowerCLI
Import-Module VMware.PowerCLI

### FUNCTION DEFINITIONS ###
Function Check-CustomizationStarted([string] $VM_Hostname) {
    Write-Host "Verifying that Customization for VM $VM_Hostname has started"
    $i=60 #time-out of 5 min
    while($i -gt 0) {
        $vmEvents = Get-VIEvent -Entity $VM_Hostname
        $startedEvent = $vmEvents | Where { $_.GetType().Name -eq "CustomizationStartedEvent" }
        if ($startedEvent) {
            Write-Host  "Customization for VM $VM_Hostname has started" 
            return $true
        }
        else {
            Start-Sleep -Seconds 5
            $i--
        }
    }
    Write-Warning "Customization for VM $VM_Hostname has failed"
    return $false
}
Function Check-CustomizatonFinished([string] $VM_Hostname){
    Write-Host  "Verifying that Customization for VM $VM_Hostname has finished" 
    $i = 60 #time-out of 5 min
    while($true){
        $vmEvents = Get-VIEvent -Entity $VM_Hostname
        $SucceededEvent = $vmEvents | Where { $_.GetType().Name -eq "CustomizationSucceeded" }
        $FailureEvent = $vmEvents | Where { $_.GetType().Name -eq "CustomizationFailed" }
        if ($FailureEvent -or ($i -eq 0)) {
            Write-Warning  "Customization of VM $VM_Hostname failed" 
            return $False
        }
    if ($SucceededEvent)
            {
    Write-Host  "Customization of VM $VM_Hostname Completed Successfully" 
    Start-Sleep -Seconds 30
    Write-Host  "Waiting for VM $VM_Hostname to complete post-customization reboot" 
    Wait-Tools -VM $VM_Hostname -TimeoutSeconds 300
    Start-Sleep -Seconds 30
    return $true
            }
    Start-Sleep -Seconds 5
    $i--
	}
}
Function Restart-VM([string] $VM_Hostname)
{
Restart-VMGuest -VM $VM_Hostname -Confirm:$false | Out-Null
Write-Host "Reboot VM $VM_Hostname" 
Start-Sleep -Seconds 60
Wait-Tools -VM $VM_Hostname -TimeoutSeconds 300 | Out-Null
Start-Sleep -Seconds 10
}
function Add-Script([string] $script,$parameters=@(),[bool] $reboot=$false){
$i=1
foreach ($parameter in $parameters)
    {
if ($parameter.GetType().Name -eq "String") {$script=$script.replace("%"+[string] $i,'"'+$parameter+'"')}
else                                        {$script=$script.replace("%"+[string] $i,[string] $parameter)}
$i++
    }
$script:scripts += ,@($script,$reboot)
}


### DEPLOY VM ###
Write-Host "Deploying Virtual Machine with Name: [$VM_Hostname] using Template: [$VI_VMTemplate] and Customization Specification: [$VI_CustomizationSpec] on cluster: [$VI_Cluster]" 
New-VM -Name $VM_Hostname -Template $VI_VMTemplate -ResourcePool $VI_Cluster -OSCustomizationSpec $VI_CustomizationSpec -Location $VI_Location -Datastore $VI_Datastore -DiskStorageFormat $VI_VMStorageFormat | Out-Null
Get-VM $VM_Hostname | Get-NetworkAdapter | Set-NetworkAdapter -Portgroup $VI_NetworkName -confirm:$false | Out-Null
Set-VM -VM $VM_Hostname -NumCpu $VM_CPU -MemoryGB $VM_Memory -Confirm:$false | Out-Null
Get-VM $VM_Hostname | Get-HardDisk | Where-Object {$_.Name -eq "Hard Disk 1"} | Set-HardDisk -CapacityGB $VM_DiskCapacity -Confirm:$false | Out-Null
Write-Host "Virtual Machine $VM_Hostname Deployed. Powering On" 
Start-VM -VM $VM_Hostname | Out-Null
if (-not (Check-CustomizationStarted $VM_Hostname)) { break }; if (-not (Check-CustomizatonFinished $VM_Hostname)) { break }
foreach ($script in $scripts)
{
Invoke-VMScript -ScriptText $script[0] -VM $VM_Hostname -GuestCredential $VM_AdminCredential | Out-Null
if ($script[1]) {Restart-VM $VM_Hostname}
}

# Assign IP
Add-Script "New-NetIPAddress -InterfaceIndex 2 -IPAddress %1 -PrefixLength %2 -DefaultGateway %3" @($VM_IP, $VM_IP_Subnet, $VM_IP_GW)
Add-Script "Set-DnsClientServerAddress -InterfaceIndex 2 -ServerAddresses %1" @($VM_IP_DNS)

### DEFINE POWERSHELL SCRIPTS TO RUN IN VM AFTER DEPLOYMENT ###
if ($JoinDomainYN.ToUpper() -eq "Y") {
    Add-Script '$DomainUser = %1;
                $DomainPWord = ConvertTo-SecureString -String %2 -AsPlainText -Force;
                $DomainCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $DomainUser, $DomainPWord;
                 Add-Computer -DomainName %3 -Credential $DomainCredential' @("$Domain\$DomainAdmin",$DomainAdminPassword, $Domain) $true }
    Add-Script 'Import-Module NetSecurity; Set-NetFirewallRule -DisplayGroup "File and Printer Sharing" -enabled True'
    Add-Script 'Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -name fDenyTSConnections -Value 0;
                Enable-NetFirewallRule -DisplayGroup "Remote Desktop";
                Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -name UserAuthentication -Value 0'
    




#New-OSCustomizationSpec -OSCustomizationSpec "$OSCustomization" -ChangeSid -AdminPassword $AdminCredentials -Domain $Domain -TimeZone 035 -DomainCredentials (Get-Credential) -AutoLogonCount 1


<#
Random Crap
Add-Script '<powershell script %1, ... %n>' @(variable1, ..., variable n) $true
$true needed for reboot after add script

#>