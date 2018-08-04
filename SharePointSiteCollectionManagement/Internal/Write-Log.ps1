Function Write-Log{
    <#
    .SYNOPSIS
    Write-Log function based on a post from an Adam Bertram blog post.

    .DESCRIPTION
    Used to log information

    .EXAMPLE
    An example

    .NOTES
    General notes
    #>

    [CmdletBinding()]
    Param (
        [Parameter()]
        [string]$LogFilePath = $env:LOCALAPPDATA,

        [Parameter(Mandatory)]
        [string]$Message,

        # Parameter help description
        [Parameter()]
        [ValidateSet('INFO','SUCCESS','ERROR')]
        [string]$Type = 'INFO',

        [Parameter()]
        [ValidateSet('1','2','3')]
        [int]$Severity = 1 ## Default to a low severity. Otherwise, override
    )

    $line = [pscustomobject]@{
        'DateTime' = (Get-Date)
        'Type' = $Type
        'Message' = $Message
        'Severity' = $Severity
    }

    ## Ensure that $LogFilePath is set to a global variable at the top of script
    $fullLogFilePath = "$LogFilePath\$($(Get-Date).ToString("yyyyMMdd"))_SiteMoveLog.log"
    Write-Verbose "$(Get-Date) - Writing to Log File to $fullLogFilePath"

    $line | Export-Csv -Path $fullLogFilePath -Append -NoTypeInformation
}