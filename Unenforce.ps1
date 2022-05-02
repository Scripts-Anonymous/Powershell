get-aduser -identity $env:USERNAME |`
set-aduser -SmartcardLogonRequired:$false
get-aduser -identity $env:USERNAME |`
Set-ADAccountPassword -Reset -NewPassword (Read-Host -AsSecureString "New Password")
pause