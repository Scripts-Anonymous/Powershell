<# Key-Standardization
  -----------------------------------------------------------------------------------------
    Author: 
	Jeff Allen
	Sr. Systems Administrator
	Version: 2021-06-18.20000000
#>
<#
    This script will License and Activate Windows 10 with the GLVK Key.
    "Key-Standardization" values:
    "0"	GLVK product key installed and activated.
    "1" GLVK product key installed. Waiting on activation.
    "2" Failed to install key.
    "3" Failed to set activation type.
    "4" Failed to activate.
#>


# Variable Defination
$RegistryPathCheck=$null
$RegistryPath=$null
$ProductKeyCheck=$null
$LicenseStatusCheck=$null
$KMSCheck=$null
$InstallProductKey=$null
$ActivationType=$null
$ActivateSuccessful=$null

# Check for Registry Path
$RegistryPathCheck=Test-Path -Path "HKLM:\Software\*SITE*\Compliance"
if ($RegistryPathCheck -eq $False){
    New-Item -Path "HKLM:\Software\*SITE*\Compliance"
}

# Set Registry Path
$RegistryPath="HKLM:\Software\*SITE*\Compliance"

# This block check to see if the key has been set previously. If the key is "0", windows is using the correct key and is activated.
if ((Get-ItemProperty -Path $RegistryPath)."Key-Standardization" -eq 0){
	Exit
}

$ProductKeyCheck=((cscript C:\windows\system32\slmgr.vbs /dli | Select-String "Partial Product Key: 2YT43") -like "Partial Product Key: 2YT43")
$LicenseStatusCheck=((cscript C:\windows\system32\slmgr.vbs /dli | Select-String "License Status: Licensed") -like "License Status: Licensed")
$KMSCheck=((cscript C:\windows\system32\slmgr.vbs /dli | Select-String "License Status: Licensed") -like "License Status: Licensed")
Switch (


else{

	if (($ProductKeyCheck -eq $true) -And ($LicenseStatusCheck -eq $true)){
		Set-ItemProperty -Path $RegistryPath -Name "Key-Standardization" -PropertyType DWORD -Value 0
	}
	#Install correct product key
	elseif($ProductKeyCheck -eq $false){
		$InstallProductKey=((cscript C:\windows\system32\slmgr.vbs /ipk "NPPR9-FWDCX-D2C8J-H872K-2YT43" | Select-String "Installed product key NPPR9-FWDCX-D2C8J-H872K-2YT43 successfully.") -like "Installed product key NPPR9-FWDCX-D2C8J-H872K-2YT43 successfully.")
		if($InstallProductKey -eq $true){
			Set-ItemProperty -Path $RegistryPath -Name "Key-Standardization" -PropertyType DWORD -Value 1
			# Change to Active Directory Based Activation
			$ActivationType=((cscript C:\windows\system32\slmgr.vbs /act-type 1 | Select-String "Volume activation type set successfully.") -like "Volume activation type set successfully.")
			if($ActivationType -eq $true){
				# Check if Activation is successful
				$ActivateSuccessful=((cscript C:\windows\system32\slmgr.vbs /ato | Select-String "Product activated successfully.") -like "Product activated successfully.")
				if ($ActivateSuccessful -eq $true){
					Set-ItemProperty -Path $RegistryPath -Name "Key-Standardization" -PropertyType DWORD -Value 0
					Exit
				}
				else{
					Set-ItemProperty -Path $RegistryPath -Name "Key-Standardization" -PropertyType DWORD -Value 4
				}
			}
			else{
				Set-ItemProperty -Path $RegistryPath -Name "Key-Standardization" -PropertyType DWORD -Value 3
			}
		}
		else{
			Set-ItemProperty -Path $RegistryPath -Name "Key-Standardization" -PropertyType DWORD -Value 2
		}
	}
	elseif($LicenseStatusCheck -eq $true){
		# Change to Active Directory Based Activation
		cscript C:\windows\system32\slmgr.vbs /act-type 1
		# Check if Activation is successful
		$ActivateSuccessful=((cscript C:\windows\system32\slmgr.vbs /ato | Select-String "Product activated successfully.") -like "Product activated successfully.")
		if ($ActivateSuccessful -eq $true){
			Set-ItemProperty -Path $RegistryPath -Name "Key-Standardization" -PropertyType DWORD -Value 0
		}
		else{
			Set-ItemProperty -Path $RegistryPath -Name "Key-Standardization" -PropertyType DWORD -Value 4
		}
	}
}
