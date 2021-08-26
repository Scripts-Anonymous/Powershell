<# Get-API_Token
    Author: 
    Jeff Allen
    im@jeffreyallen.tech
#>
$Creds=Get-credentials
$Username=$Creds.Username
$Password=$Creds.GetNetworkCredential().Password
$RequestURL="https://localhost:8080/auth/realms/stigman/protocol/openid-connect/token"
$body=@{
    grant_type='password'
    username=$Username
    password=$Password
    client_id='stig-manager'
    client_secret='client_secret'
}
$Result=Invoke-RestMethod -Method POST -URI $RequestURL -ContentType "application/x-www-form-urlencoded" -Body $Body -Credentials $Creds
$global:AccessToken=($Results.access_token) | ConvertTo-SecureString - AsPlainText -Force
$global:RefreshToken=($Results.refresh_token) | ConvertTo-SecureString - AsPlainText -Force