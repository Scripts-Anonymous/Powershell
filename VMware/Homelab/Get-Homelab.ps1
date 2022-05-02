<# Deploy-VM
    Author: 
    Jeff Allen
    im@jeffreyallen.tech
# Deploy Windows Server in vCenter
# Original script from https://metisgroep.nl/blog/powercli-deploy-and-customize-a-vm-vcenter/. Modified to fit infrastructure as code.
#>
#Requires -Modules VMware.PowerCLI

### Parameters ###
param(
    [parameter(Mandatory=$True)]
    [String]$CSVPath
)

### USER DEFINED VARIABLES ###
# VMware Tags
$Category_Name = "Infra-As-Code"

### FUNCTION DEFINITIONS ###
Function Update-CustomizationStarted([string] $VM)
{
    Write-Host "Verifying that Customization for VM $VM has started"
    $i=60 #time-out of 5 min
	while($i -gt 0)
	{
		$vmEvents = Get-VIEvent -Entity $VM
		$startedEvent = $vmEvents | Where-Object { $_.GetType().Name -eq "CustomizationStartedEvent" }
		if ($startedEvent)
		{
            Write-Host  "Customization for VM $VM has started" 
			return $true
		}
		else
		{
			Start-Sleep -Seconds 5
            $i--
		}
	}
    Write-Warning "Customization for VM $VM has failed"
    return $false
}
Function Update-CustomizatonFinished([string] $VM)
{
    Write-Host  "Verifying that Customization for VM $VM has finished" 
    $i = 60 #time-out of 5 min
	while($true)
	{
		$vmEvents = Get-VIEvent -Entity $VM
		$SucceededEvent = $vmEvents | Where-Object { $_.GetType().Name -eq "CustomizationSucceeded" }
        $FailureEvent = $vmEvents | Where-Object { $_.GetType().Name -eq "CustomizationFailed" }
		if ($FailureEvent -or ($i -eq 0))
		{
			Write-Warning  "Customization of VM $VM failed" 
            return $False
		}
		if ($SucceededEvent)
		{
            Write-Host  "Customization of VM $VM Completed Successfully" 
            Start-Sleep -Seconds 30
            Write-Host  "Waiting for VM $VM to complete post-customization reboot" 
            Wait-Tools -VM $VM -TimeoutSeconds 300
            Start-Sleep -Seconds 30
            return $true
		}
        Start-Sleep -Seconds 5
        $i--
	}
}
Function Restart-VM([string] $VM)
{
    Restart-VMGuest -VM $VM -Confirm:$false | Out-Null
    Write-Host "Reboot VM $VM" 
    Start-Sleep -Seconds 60
    Wait-Tools -VM $VM -TimeoutSeconds 300 | Out-Null
    Start-Sleep -Seconds 10
}
Function Add-Script([string] $script,$parameters=@(),[bool] $reboot=$false){
    $i=1
    foreach ($parameter in $parameters)
    {
        if ($parameter.GetType().Name -eq "String") {$script=$script.replace("%"+[string] $i,'"'+$parameter+'"')}
        else                                        {$script=$script.replace("%"+[string] $i,[string] $parameter)}
        $i++
    }
    $script:scripts += ,@($script,$reboot)
}
Function Test-IP([string] $IP)
{
  if (-not ($IP) -or (([bool]($IP -as [IPADDRESS])))) { return $true} else {return $false}
}
Function New-VMwareTags {
    If (-not (Get-TagCategory -Name $Category_Name)){
        New-TagCategory -Name $Category_Name
    }
    $Tag_Names = @($CSV.Tag_Name) | Sort -Unique
    ForEach ($Tag_Name in $Tag_Names){
        If (!(Get-Tag -Name $Tag_Name)){
            New-Tag -Name $Tag_Name -Category $Category_Name
        }
    }
}

### CSV Checks ###
Clear-Host
Write-host "Checking CSV" -Foregroundcolor Green
$CSV = Import-CSV -Path $CSVPath
$VMs = @($CSV)
ForEach ($VM in $VMs){
    # Cluster Check
    if (-not (Get-Cluster -Name $VM.Cluster)) {
        Write-Host "The" $VM.Cluster "for" $VM.VM_Name "does not exist. Please check for typos." -ForegroundColor Red
        Pause
    }
    # Hostname Checks
    elseif (($VM.VM_Name).Length -gt 15) {
        Write-Host $VM.VM_Name "is to long. Please limit hostnames/VM names to 15 characters." -ForegroundColor Red
        Pause
    }
    elseif (-not (Get-VM -Name $VM.VM_Name)){
        Write-Host $VM.VM_Name "already exists." -ForegroundColor Red
        Pause
    }
    # IP/GW/DNS check
    elseif (-not ((Test-IP $VM.IP_Address) -and (Test-IP $VM.GW) -and (Test-IP $VM.IP_DNS1) -and (Test-IP $VM.IP_DNS2))) {
        Write-Host $VM.VM_Name "has an invalid IP address." -ForegroundColor Red 
        Pause
    }
    else {
        Write-Host "CSV is properly Formated" -ForegroundColor Green
    }
}

### Create VMware Tags ###
New-VMwareTags

<#
### READ CREDENTIALS ###
Get-Content credentials.txt | Foreach-Object{
   $var = $_.Split('=')
   Set-Variable -Name $var[0].trim('" ') -Value $var[1].trim('" ')
}
$VMLocalUser = "$Hostname\$LocalUser"
$VMLocalPWord = ConvertTo-SecureString -String $LocalPassword -AsPlainText -Force
$VMLocalCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $VMLocalUser, $VMLocalPWord
#>

### CONNECT TO VCENTER ###
Get-Module -ListAvailable VMware* | Import-Module | Out-Null
Connect-VIServer -Server $vCenterServer
$SourceVMTemplate = Get-Template -Name $VMTemplate
$SourceCustomSpec = Get-OSCustomizationSpec -Name $CustomSpec

foreach ($VM in $VMs){
    ### DEFINE POWERSHELL SCRIPTS TO RUN IN VM AFTER DEPLOYMENT ###
    if ($VM.IP_Address) {
        Add-Script "New-NetIPAddress -InterfaceIndex 2 -IPAddress %1 -PrefixLength %2 -DefaultGateway %3" @($VM.IP_Address, $VM.SubnetLength, $VM.GW)
        Add-Script "Set-DnsClientServerAddress -InterfaceIndex 2 -ServerAddresses %1,%2" @($VM.IP_DNS1,$VM.IP_DNS2)
    }
    <#
    if ($JoinDomainYN.ToUpper() -eq "Y") {
        Add-Script '$DomainUser = %1;
        $DomainPWord = ConvertTo-SecureString -String %2 -AsPlainText -Force;
        $DomainCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $DomainUser, $DomainPWord;
        Add-Computer -DomainName %3 -Credential $DomainCredential' @("$Domain\$DomainJoinAdmin",$DomainJoinAdminPassword, $Domain) $true
    }
    Add-Script 'Import-Module NetSecurity; Set-NetFirewallRule -DisplayGroup "File and Printer Sharing" -enabled True'
    Add-Script 'Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -name fDenyTSConnections -Value 0;
        Enable-NetFirewallRule -DisplayGroup "Remote Desktop";
        Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -name UserAuthentication -Value 0'
    #>
    
    ### DEPLOY VM ###
    Write-Host "Deploying the following Virtual Machine:"
    Write-Host "Name:" $VM.VM_Name
    Write-Host "Template:" $SourceVMTemplate
    Write-Host "Customization Specification:" $SourceCustomSpec
    Write-Host "Cluster:" $VM.Cluster
    New-VM -Name $VM.VM_Name -Template $SourceVMTemplate -ResourcePool $VM.Cluster -OSCustomizationSpec $SourceCustomSpec -Location $VM.Location -Datastore $VM.Datastore -DiskStorageFormat $VM.DiskStorageFormat | Out-Null
    New-TagAssignment -Entity $VM.VM_Name -Tag $VM.Tag_Name
    Get-VM -Name $VM.VM_Name | Get-NetworkAdapter | Set-NetworkAdapter -Portgroup $VM.NetworkName -confirm:$false | Out-Null
    Set-VM -Name $VM.VM_Name -NumCpu $VM.CPU -MemoryGB $VM.Memory -Confirm:$false | Out-Null
    Get-VM -Name $VM.VM_Name | Get-HardDisk | Where-Object {$_.Name -eq "Hard Disk 1"} | Set-HardDisk -CapacityGB $VM.DiskCapacity -Confirm:$false | Out-Null
    Write-Host "Virtual Machine" $VM.VM_Name "deployed. Powering On" 
    Start-VM -VM $VM.VM_Name | Out-Null
    if (-not (Update-CustomizationStarted $VM.VM_Name)) { break }; if (-not (Update-CustomizatonFinished $VM.VM_Name)) { break }
    foreach ($script in $scripts) {
        Invoke-VMScript -ScriptText $script[0] -VM $VM.VM_Name -GuestCredential $VMLocalCredential | Out-Null
        if ($script[1]) {Restart-VM $VM.VM_Name}
    }
    ### End of Script ###
    Write-Host "Deployment of VM" $VM.VM_Name "finished" 
}