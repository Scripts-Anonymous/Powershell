<# API.psm1
    Author:
    Jeff Allen
    https://github.com/Scripts-Anonymous/Powershell/tree/main/API
#>
Function Get-APIToken {
<#
.SYNOPSIS
    This script will get a bearer token from a keycloak based authentication source.

.DESCRIPTION
    This script is designed to call a keycloak realm (stigman) and provide the user/script a bearer token to make follow up API calls.

.OUTPUTS
    $global:AccessToken is available to run API calls.

.EXAMPLE
    PS> .\Get-API_Token -URL https://localhost:8080/auth/realms/stigman -Client_ID stig-manager - Client_Secret ####
    Will provide an Access and Refresh token.

#>
    #Function Body
        # User Variables
    $URL="https://localhost:8080/auth/realms/stigman"
    $Client_ID="stig-manager"
    $Client_Secret=""
    $URI=$URL+"/protocol/openid-connect/token"
    
    If(!($global:RefreshToken)){
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
        $global:RefreshToken=($Response.refresh_token) | ConvertTo-SecureString -AsPlainText -Force
    }
    Else{
        #Exchange Refresh token for access token.
        $body=@{
        grant_type='refresh_token'
        refresh_token=$global:RefreshToken
        client_id=$Client_ID
        client_secret=$Client_Secret
        }
        $Response=Invoke-RestMethod -Method POST -URI $URI -ContentType "application/x-www-form-urlencoded" -Body $Body
        $Response
        $global:AccessToken=($Response.access_token) | ConvertTo-SecureString -AsPlainText -Force
        $global:RefreshToken=($Response.refresh_token) | ConvertTo-SecureString -AsPlainText -Force
    }
}