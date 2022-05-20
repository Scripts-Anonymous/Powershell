<# Get-VMW_vSphere_6-7_ESXi_STIG_V1R2.ps1
    Author: 
	Jeff Allen
	Sr. Systems Administrator
	Version: 
#>
#get date
$date = Get-date -format u
$date = $date.split(" ")
$date[0] = $date[0] -replace " ","_"
$date[0] = $date[0] -replace "-",""
$date[0] = $date[0] -replace ":",""
$date = $date[0]

$vCenter="*FQDN*"
#$SyslogHostFQDN="*FQDN*"
#$SyslogPort="*PORT*"
#$SyslogConn="tcp"
#$domain="*DOMAIN*"
#$esxAdminsGroup="*GROUPNAME*"
#$VMHostNTPServer="*NTPSERVER*"
#$VMotionKernelVLanId="*VLAN*"
#$ManagementKernelVLanId="*VLAN*"
#$ReservedVLANs=$Cisco
#$ESXiServiceAccount="*SERVICEACCOUNT*"
$VMs=@(Get-VM | Sort Name)

#Random Variables
#$FullSyslogHost=$SyslogConn + "://" + $SyslogHostFQDN + ":" + $SyslogPort
#$Cisco= 3968..4047


#Foreach($VM in $VMs){
    # Create Hostname and IP
    $HOST_NAME=Get-VM $VM
    $ipAddress=Get-VM $VM | Select Name,@{N="IP";E={@($_.guest.IPAddress[0])}}

    # Create the resulting xml file that is to be turned into a ckl for STIG Viewer
    New-Item ./"$HOST_NAME"_VMW_vSphere_6-7_Virtual_Machine_STIG_V1R2_Results.ckl -ItemType file -Force
    $results = Get-Item ./"$HOST_NAME"_VMW_vSphere_6-7_Virtual_Machine_STIG_V1R2_Results.ckl
    
    # Set the location for the clean template of the ckl file.
    $checkFilePath = "./Template-VMW_vSphere_6-7_Virtual_Machine_STIG_V1R2.ckl"
    $checkFile = Get-Item $checkFilePath

    #'$xml' is going to be the checklist we write to
    [xml]$xml = Get-Content $checkFile
    $xml.PreserveWhitespace = 'true'
    
    #Update server info in checklist
    $xml.CHECKLIST.ASSET.HOST_NAME = [string]$HOST_NAME.Name
    $xml.CHECKLIST.ASSET.HOST_FQDN = [string]$VM + "*DOMAIN*"
    $xml.CHECKLIST.ASSET.HOST_IP = [string]$ipAddress.IP

    ##########################################################################################################################################################################################################
    $VULNERABILITY = 'V-239332'
    Write-Host "-------------------------$VULNERABILITY------------------------"
    #go to the appropriate node in the checklist
    $node = $xml.CHECKLIST.STIGS.iSTIG.VULN | foreach{$_.STIG_DATA | where-object{$_.VULN_ATTRIBUTE -eq 'Vuln_Num' -and $_.Attribute_Data -eq $VULNERABILITY}}
    $node.ParentNode.Comments = "`r`n"#put something in the comment section of the parent node, if we don't it seems spotty as to whether or not we can save the commentResults variable there
    #clear the comment contents variable
    $commentResults = ''
    $vulnCheck=Get-VM $VM | Get-AdvancedSetting -Name isolation.tools.copy.disable
    $vulnComment=Get-VM $VM | Get-AdvancedSetting -Name isolation.tools.copy.disable | Format-Table -AutoSize
    $vulnResult=$true
    if($vulnCheck.value -eq $vulnResult){
        $commentResults += "" | Out-String
        $commentResults += $vulnComment | out-string
        $node.ParentNode.Comments = $commentResults 
        $node.ParentNode.FINDING_DETAILS = ''
        $node.ParentNode.STATUS = "NotAFinding"
    }
    else{
        $commentResults += "" | Out-String     
        $commentResults += $vulnComment | out-string
        $node.ParentNode.Comments = $commentResults 
        $node.ParentNode.FINDING_DETAILS = ''
        $node.ParentNode.STATUS = "Open"
    }
    #Save results      
    $xml.Save($results.Fullname)
#}