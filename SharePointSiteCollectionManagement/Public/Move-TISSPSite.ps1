Function Move-TISSPSite{
    <#
    .SYNOPSIS
    Move a site collection from one content database to another content database.

    .DESCRIPTION
    Long description

    .PARAMETER siteCollectionUrl
    The URL of the site collection to be moved.

    .PARAMETER contentDatabaseName
    The name of the target content database to where the site collection should be moved.

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
        [string]$contentDatabaseName,

        [switch]$SuppressSPSiteMoveConfirm
    )

    Begin{
        $success = $false
    }

    Process{
        if ($PSCmdlet.ShouldProcess($param)) {
            try{
                $site = Get-SPSite $siteCollectionUrl
                $destinationDB = $contentDatabaseName

                $msg = "Moving $($site.RootWeb.Title) site collection from $($site.ContentDatabase.Name) to $destinationDB"
                Write-Verbose $msg
                Write-Log -Message $msg -Severity 1

                $params = @{
                    Identity = $site
                    DestinationDatabase = $destinationDB
                }

                if($SuppressSPSiteMoveConfirm){
                    $params.Add("confirm",$false)
                }

                Move-SPSite @params -errorAction Stop

                $success = $true
                $msg = "Success - $($site.RootWeb.Title) site collection from $($site.ContentDatabase.Name) to $destinationDB"
                Write-Verbose $msg
                Write-Log -Message $msg -Severity 1 -Type SUCCESS
            }
            catch{
                $success = $false

                $msg = "There was an issue moving $siteCollectionUrl to $destinationDB. "
                $msg += $_.Exception.Message
                Write-Verbose $msg
                Write-Log -Message $msg -Severity 3 -Type ERROR
            }
            finally{
                $success
            }
        }
    }

    End{

    }
}