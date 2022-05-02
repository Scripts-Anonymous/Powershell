<# Certificate-Submit_Retrieve
  -----------------------------------------------------------------------------------------
    Author: 
	Jeff Allen
	Version: 2021-06-15.2
    This script will find all CSRs in a folder and submit/retrieve (one at a time) them from a CA. Certificate approval must be done manually.
    To Do:
	    Error handling
		    Get-CertificationAuthority fails (get successful gpupdate)
        Get Available Templates and allow user to choose
#>
#Requires -Modules PSPKI
# Module Import
Import-Module PSPKI

# Parameter definiations
param(
	[parameter(Mandatory=$false)]
	[String]$path,
	[parameter(Mandatory=$false)]
	[Switch]$verboselog
)

# Get available Certificate Authority
$allca=Get-CertificationAuthority
if($allca.count -eq 0){
	$ca=$a[0].ComputerName
}
else{
	$allca
	$ca=Read-Host "Please choose a Certificate Authority by ComputerName"
}

# Basic CSR Validation
$CSRs=Get-Childitem -Path "$certpath"
ForEach($CSR in $CSRs){
    $ValidCSR=Get-ChildItem $CSR | Select-String -Pattern '-----BEGIN CERTIFICATE REQUEST-----','-----END CERTIFICATE REQUEST-----'
    If ([bool](($ValidCSR).Line -eq '-----BEGIN CERTIFICATE REQUEST-----') -AND (($ValidCSR).Line -eq '-----END CERTIFICATE REQUEST-----')){
        Write-Host "$CSR is a valid certificate"
    }
    Else{
        Write-Host "$CSR is not a valid certificate"
    }
}

# Get current users "PKIRequest" groups
$CurrentUser=(Get-ADUser (Get-ChildItem env:\username).value)
$TemplateSecurityGroups=@(Get-ADGroup -LDAPFilter ("(member:1.2.840.113556.1.4.1941:={0})" -f $CurrentUser) | Select-Object -Expand Name | Sort-Object Name | Select-String -SimpleMatch "PKIRequest")
# $TemplateSecurityGroups
# Write-Host "If these groups don't look correct, please contact your sites' Active Directory Administrator(s) or local Helpdesk"

# Get WC User is from
<#if($TemplateSecurityGroups -eq $null){
    Write-Host "You don't seem to have any PKIRequest groups associated with your account. Please contact your sites' Active Directory Administrator(s) or local Helpdesk"
}
Else{
$WCShortCode=$TemplateSecurityGroups[0].ToString()
}
#>

# Get "PKIRequest" Templates


# Get "PKIApprover" Users
	

if ($path.length -eq 0){
	$certpath=Read-Host "Where are the CSRs located?"
	Foreach($cert in $certs){
		$request=Submit-CertificateRequest -Path $cert -CertificationAuthority $ca -Attribute CertificateTemplate:*TEMPLATENAME*
		Write-host "Please approve cert then come back and continue..."
		Pause
		$issuedcert=Get-IssuedRequest -CertificationAuthority *CERTIFICATEAUTHORITY* -RequestID $request.requestid -Property RawCertificate
		$certname=$cert.basename
		"-----BEGIN CERTIFICATE-----" | Out-File $certpath\$certname.cer
		$issuedcert.RawCertificate.trim("`r`n") | Out-File $certpath\$certname.cer -Append
		"-----END CERTIFICATE-----" | Out-File $certpath\$certname.cer -Append
		Write-Host "Certificate written to the same location as the CSRs."
	}

}
else{
	$certs=Get-Childitem *.csr -Path "$certpath"
	Foreach($cert in $certs){
		$request=Submit-CertificateRequest -Path $cert -CertificationAuthority $ca -Attribute CertificateTemplate:*TEMPLATENAME*
		Write-host "Please approve cert then come back and continue..."
		Pause
		$issuedcert=Get-IssuedRequest -CertificationAuthority *CERTIFICATEAUTHORITY* -RequestID $request.requestid -Property RawCertificate
		$certname=$cert.basename
		"-----BEGIN CERTIFICATE-----" | Out-File $certpath\$certname.cer
		$issuedcert.RawCertificate.trim("`r`n") | Out-File $certpath\$certname.cer -Append
		"-----END CERTIFICATE-----" | Out-File $certpath\$certname.cer -Append
		Write-Host "Certificate written to the same location as the CSRs."
	}
}

