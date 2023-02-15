<#
    .NAME
    Set-Logging

    .AUTHOR
    Jeff Allen

    .SYNOPSIS
    This function sets environment variables for logs (LogOnly), script output (ReportOnly), and/or transcripts (TranscriptOnly). You can view the variables by running an "ls env:".

    .DESCRIPTION
    To enable environment variables please run "Set-Logging" and/or change all scripts to run "Set-Logging" as their first command.

    .RELATED LINKS
    GITHUB link:

    .EXAMPLE
    PS> .\

    .EXAMPLE
    PS> .\

#>

#Requires -Version 5

function Set-Logging {
    param (
        [parameter(Mandatory=$False)]
        [ValidateSet("LogOnly","ReportOnly","TranscriptOnly","RemoveAll")]
        [Switch]$Option
    )

    # Variables
    $LogEnvName = "Logs"
    $LogPath = "C:\Scripts\Logs"
    $ReportEnvName = "Reports"
    $ReportPath = "C:\Scripts\Reports"
    $TranscriptEnvName = "Transcripts"
    $TranscriptPath = "C:\Scripts\Transcripts"

    Switch ($Option) {
        "LogOnly"    {
            New-Item -Path Env: -Name $LogEnvName -Value $LogPath
        }        
        "ReportOnly"    {
            New-Item -Path Env: -Name $ReportEnvName -Value $ReportPath
        }
        "TranscriptOnly"  {
            New-Item -Path Env: -Name $TranscriptEnvName -Value $TranscriptPath
        }
        Default {
            New-Item -Path Env: -Name $LogEnvName -Value $LogPath
            New-Item -Path Env: -Name $ReportEnvName -Value $ReportPath
            New-Item -Path Env: -Name $TranscriptEnvName -Value $TranscriptPath
        }
        "RemoveAll"    {
            Remove-Item Env:$LogEnvName
            Remove-Item Env:$ReportEnvName
            Remove-Item Env:$TranscriptEnvName
        }
    }
}