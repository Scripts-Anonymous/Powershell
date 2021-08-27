<# Get-API_Token
    Author:
    Jeff Allen
    im@jeffreyallen.tech
#>
<#
    .SYNOPSIS
    This script will get a bearer token from a keycloak based authentication source.

    .DESCRIPTION
    This script is designed to call a keycloak realm (stigman) and provide the user/script a bearer token to make follow up API calls.

    .PARAMETERS
    -URL <string>
        Required?                    True

    -Client_ID <string>
        Required?                    True

    -Client_Secret <string>
        Required?                    True

    .OUTPUTS
    $global:AccessToken is available to the user to run API calls.
    $global:RefreshToken is available to the user to refresh the Access Token.

    .EXAMPLE
    PS> .\Get-API_Token -URL https://localhost:54000/auth/realms/stigman -Client_ID stig-manager - Client_Secret ####
    Will provide an Access and Refresh token.

    .EXAMPLE
    PS> .\Get-API_Token -RefreshToken $True
    Will refresh the access token.
#>

param(
    [parameter(Mandatory=$False)]
    [String]$URL,
    [parameter(Mandatory=$False)]
    [String]$Client_ID,
    [parameter(Mandatory=$False)]
    [String]$Client_Secret,
    [parameter(Mandatory=$False)]
    [Bool]$RefreshToken
)

# Variables
$URL="https://localhost:8080/auth/realms/stigman"
$Client_ID="stig-manager"
$Client_Secret=""

If (($global:AccessToken -eq $null) -or ([int]$global:RefreshTimer -lt [int](Get-Date -UFormat %s))){
#Get Access Token
$Creds=Get-Credential
    $Username=$Creds.Username
    $Password=$Creds.GetNetworkCredential().Password
    $URI=$URL+"/protocol/openid-connect/token"
    $body=@{
        grant_type='password'
        username=$Username
        password=$Password
        client_id=$Client_ID
        client_secret=$Client_Secret
    }
    $Results=Invoke-RestMethod -Method POST -URI $URI -ContentType "application/x-www-form-urlencoded" -Body $Body -Credential $Creds
    $Results
    $global:AccessToken=($Results.access_token) | ConvertTo-SecureString -AsPlainText -Force
    $global:RefreshToken=($Results.refresh_token) | ConvertTo-SecureString -AsPlainText -Force
    $global:AccessTimer=[int](Get-Date -UFormat %s)+[int]($Results.expires_in)
    $global:RefreshTimer=[int](Get-Date -UFormat %s)+[int]($Results.refresh_expires_in)
}
Elseif([int]$global:AccessTimer -gt [int](Get-Date -UFormat %s)){
$AccessLeftSeconds=([int]$global:AccessTimer)-[int](Get-Date -UFormat %s)
Write-Host "You're currently authenticated for" $AccessLeftSeconds "Seconds."
}
Else{
#Refresh Access Token
$URI=$URL+"/protocol/openid-connect/token"
$body=@{
grant_type='refresh_token'
refresh_token=$global:RefreshToken
client_id=$Client_ID
client_secret=$Client_Secret
}
$Results=Invoke-RestMethod -Method POST -URI $URI -ContentType "application/x-www-form-urlencoded" -Body $Body -Credential $Creds
$Results
$global:AccessToken=($Results.access_token) | ConvertTo-SecureString -AsPlainText -Force
$global:RefreshToken=($Results.refresh_token) | ConvertTo-SecureString -AsPlainText -Force
    $global:AccessTimer=[int](Get-Date -UFormat %s)+[int]($Results.expires_in)
    $global:RefreshTimer=[int](Get-Date -UFormat %s)+[int]($Results.refresh_expires_in)
}