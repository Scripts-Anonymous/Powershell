<#
    .NAME
    Set-Logging

    .AUTHOR
    Jeff Allen

    .SYNOPSIS
    This function sets environment variables for script output (ReportOnly) and/or transcripts (TranscriptOnly). You can view the variables by running an "ls env:".

    .RELATED LINKS
    GITHUB link:

    .EXAMPLE
    PS> .\

    .EXAMPLE
    PS> .\

#>

#Requires Powershell 5

function Set-Logging {
    param (
        [parameter(Mandatory=$False)]
        [ValidateSet("ReportOnly","TranscriptOnly","Remove")]
        [Switch]$Option
    )

    # Variables
    $ReportEnvName = "Report"
    $ReportPath = "C:\Scripts\Reports"
    $TranscriptEnvName = "Transcript"
    $TranscriptPath = "C:\Scripts\Transcripts"

    Switch ($Option) {
        "ReportOnly"    {
            New-Item -Path Env: -Name $ReportEnvName -Value $ReportPath
        }
        "TranscriptOnly"  {
            New-Item -Path Env: -Name $TranscriptEnvName -Value $TranscriptPath
        }
        Default {
            New-Item -Path Env: -Name $ReportEnvName -Value $ReportPath
            New-Item -Path Env: -Name $TranscriptEnvName -Value $TranscriptPath
        }
        "Remove"    {
            Remove-Item Env:$ReportEnvName
            Remove-Item Env:$TranscriptEnvName
        }
    }
}