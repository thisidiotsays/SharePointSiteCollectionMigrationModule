Function Set-TISSPSiteLockStatus{
    <#
    .SYNOPSIS
    Sets whether a site is Read-Only or unlocked

    .DESCRIPTION
    Long description

    .PARAMETER siteCollectionUrl
    The URL of the site collection to be changed.

    .EXAMPLE
    An example

    .NOTES
    General notes
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]$siteCollectionUrl,

        [Parameter(Mandatory)]
        [ValidateSet('ReadOnly','Unlock')]
        [string]$lockStatus
    )

    Begin{
        $success=$false
    }

    Process {
        try{
            $msg = "Setting $siteCollectionUrl Lock State to $lockStatus"
            Write-Verbose $msg
            Write-Log -Message $msg

            $site = Get-SPSite $SiteCollectionUrl -erroraction Stop
            Set-SPSite -Identity $site -LockState $lockStatus -erroraction Stop

            $msg = "$siteCollectionUrl Lock State set to $lockStatus"
            Write-Verbose $msg
            Write-Log -Message $msg -Type SUCCESS

            $success = $true
        }catch{
            $msg = "There was an issues setting the lock status of $siteCollectionUrl to $lockStatus. "
            $msg += $_.Exception.Message

            Write-Verbose $msg
            Write-Log -Message $msg -Severity 3 -Type ERROR

            $success = $false
        }finally{
            $success
        }
    }

    End{

    }
}