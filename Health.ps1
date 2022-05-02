Option 1

$CurrentUser=(Get-ADUser (Get-ChildItem env:\username).value)
if (($CurrentUser.sAMAccountName) -like ".serv"){
	$Servers=Get-ADComputer -Filter "operatingSystem -like '*Server*'" -SearchBase "OU=*OU*,DC=*DOMAIN*"
	foreach ($server in $Servers){
		Write-Host "Do a little dance"
	}
}
elseif(($CurrentUser.sAMAccountName) -like ".paw"){
	$Servers=Get-ADComputer -Filter "operatingSystem -like '*10*'" -SearchBase "OU=*OU*,DC=*DOMAIN*"
	foreach ($server in $Servers){
		Write-Host "Make a little love"
	}
}
else{
	$Servers=Get-ADComputer -Filter "operatingSystem -like '*Server*'" -SearchBase "OU=Domain Controllers,DC=*DOMAIN*" -Server *PDC*
	foreach ($server in $Servers){
		Write-Host "Get down tonight"
	}
}





Option 2

$CurrentUser=(Get-ADUser (Get-ChildItem env:\username).value)
Switch($CurrentUser){
	(($CurrentUser.sAMAccountName) -like ".serv"){
		$Servers=Get-ADComputer -Filter "operatingSystem -like '*Server*'" -SearchBase "OU=*OU*,DC=*DOMAIN*"
		foreach ($server in $Servers){
			Write-Host "Do a little dance"
		}
	}
	(($CurrentUser.sAMAccountName) -like ".paw"){
		$Servers=Get-ADComputer -Filter "operatingSystem -like '*10*'" -SearchBase "OU=*OU*,DC=*DOMAIN*"
		foreach ($server in $Servers){
			Write-Host "Make a little love"
		}
	}
	(($CurrentUser.sAMAccountName) -like ".T1DA"){
		$Servers=Get-ADComputer -Filter "operatingSystem -like '*Server*'" -SearchBase "OU=Domain Controllers,DC=*DOMAIN*" -Server *PDC*
		foreach ($server in $Servers){
			Write-Host "Get down tonight"
		}
	}
	(($CurrentUser.sAMAccountName) -like ".T0DA"){
		$Servers=Get-ADComputer -Filter "operatingSystem -like '*Server*'" -SearchBase "OU=Domain Controllers,DC=*DOMAIN*"
		foreach ($server in $Servers){
			Write-Host "Do do"
		}
	}
	(($CurrentUser.sAMAccountName) -like ".MEM"){
		$Servers=Get-ADComputer -Filter "operatingSystem -like '*Server*'" -SearchBase "OU=Domain Controllers,DC=*DOMAIN*" -Server *PDC*
		foreach ($server in $Servers){
			Write-Host "Get down tonight"
		}
	}
}
