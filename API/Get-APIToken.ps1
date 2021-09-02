<# Get-APIToken
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

# User Variables
$URL="https://localhost:8080/auth/realms/stigman"
$Client_ID="stig-manager"
$Client_Secret=""

# Script Variables
$URI=$URL+"/protocol/openid-connect/token"
Function Get-APIToken {
    If(!($RefreshToken)){
        #Get Access Token
        $Creds=Get-Credential
        $Username=$Creds.Username
        $Password=$Creds.GetNetworkCredential().Password
        $body=@{
            grant_type='password'
            username=$Username
            password=$Password
            client_id=$Client_ID
            client_secret=$Client_Secret
        }
        $Response=Invoke-RestMethod -Method POST -URI $URI -ContentType "application/x-www-form-urlencoded" -Body $Body -Credential $Creds
        $Response
        $global:AccessToken=($Response.access_token) | ConvertTo-SecureString -AsPlainText -Force
        $RefreshToken=($Response.refresh_token) | ConvertTo-SecureString -AsPlainText -Force
    }
    Else{
        #Exchange Refresh token for access token.
        $body=@{
        grant_type='refresh_token'
        refresh_token=$RefreshToken
        client_id=$Client_ID
        client_secret=$Client_Secret
        }
        $Response=Invoke-RestMethod -Method POST -URI $URI -ContentType "application/x-www-form-urlencoded" -Body $Body
        $Response
        $global:AccessToken=($Response.access_token) | ConvertTo-SecureString -AsPlainText -Force
        $RefreshToken=($Response.refresh_token) | ConvertTo-SecureString -AsPlainText -Force
    }
}