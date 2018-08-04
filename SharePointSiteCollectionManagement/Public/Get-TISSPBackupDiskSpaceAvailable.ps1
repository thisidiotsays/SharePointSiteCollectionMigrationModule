Function Get-TISSPBackupDiskSpaceAvailable{
    <#
    .SYNOPSIS
    Check the drive you are backing up to has enough space. Only works with local drives at the moment

    .DESCRIPTION
    Long description

    .EXAMPLE
    An example

    .PARAMETER siteCollectionUrl
    The URL of the site collection to be backed up.

    .PARAMETER path
    The path of the folder where the backup will be stored. This folder must already exist.

    .NOTES
    General notes
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]$siteCollectionUrl,

        [Parameter(Mandatory)]
        [ValidateScript({Test-Path $_})]
        [string]$path,

        [int]$freespaceBuffer = 5
    )

    Begin{
        $success = $false
    }

    Process{
        try{
            Write-Verbose "Getting $siteCollectionUrl"
            $site = Get-SPSite $siteCollectionUrl

            $siteDiskUsed = $site.Usage.Storage/1MB
            Write-Verbose "Space used by site: $($siteDiskUsed)MB"

            $recyclebinsize = 0
            foreach($item in $site.RecycleBin){
                if($item.ItemState -eq "SecondStageRecycleBin"){
                    $recyclebinsize += $item.Size/1MB
                }
            }

            Write-Verbose "Space used by site's 2nd stage recycle bin: $($recyclebinsize)MB"

            $totalsitespace = $siteDiskUsed + $recyclebinsize
            Write-Verbose "Total space used by site content: $($totalsitespace)MB"

            $diskfreeSpace = Get-WmiObject win32_LogicalDIsk | Where-Object DeviceID -eq "F:" | Select-Object @{label="SizeInMB";Expression={[System.Math]::Round($_.FreeSpace/1MB, 0)}} | Select-Object -ExpandProperty SizeInMB
            Write-Verbose "Free space left on target disk: $($diskfreespace)MB"

            $spaceLeft = $diskfreeSpace - $siteDiskUsed
            Write-Verbose "Free space left on target disk after back: $($spaceLeft)MB"

            $success = $true
        }
        catch{

        }
        finally{
            $success
        }
    }
}