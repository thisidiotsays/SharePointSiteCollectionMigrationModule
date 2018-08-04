Function Backup-TISSPSiteToDisk{
    <#
    .SYNOPSIS
    Back up the specified site collection to a file location.

    .DESCRIPTION
    Backups a site collection to a specified file location. Also, gives the ability to set the site to readOnly and Unlocked before and after the backup process. The .bak file will be named using the current date time in yyyyMMdd_HHmmss format plus the title of the root web from the site collection.

    .EXAMPLE
    Backup-TISSPSiteToDisk -siteCollectionUrl https://intranet.domain.com -path F:\SPSiteBackups

    This will backup the http://intranet.domain.com site collection to the F:\SPSiteBackups directory. The site collection will be set to readonly prior to the backup and will be unlocked after the backup has been taken.

     .EXAMPLE
    Backup-TISSPSiteToDisk -siteCollectionUrl https://intranet.domain.com -path F:\SPSiteBackups -unlockSiteAfterBackup $false

    This will backup the http://intranet.domain.com site collection to the F:\SPSiteBackups directory. The site collection will not be unlocked after the backup. This can be useful if you are moving site collections and want to unlock them manually after doing an IIS Reset to complete the move process.

    .PARAMETER siteCollectionUrl
    The URL of the site collection to be backed up.

    .PARAMETER path
    The path of the folder where the backup will be stored. This folder must already exist.

    .PARAMETER unlockSiteAfterBackup
    Set the Lockstate of the site collection to unlock after the backup has been taken. The default value is $true.

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

        [bool]$unlockSiteAfterBackup = $true

    )

    Begin{
        $success = $false
    }

    Process{
        try{
            $msg = "Getting $siteCollectionUrl"
            Write-Verbose $msg
            Write-Log -Message $msg

            $site = Get-SPSite $siteCollectionUrl -errorAction Stop

            $success = Set-TISSPSiteLockStatus -siteCollectionUrl $siteCollectionUrl -lockStatus ReadOnly

            if($success -eq $true){
                if($path.EndsWith("\")){
                    $path = $path.Substring(0,$path.Length-1)
                }

                $filename = "$((Get-Date).ToString("yyyyMMdd_HHmmss"))$($site.RootWeb.Title.Replace(' ','')).bak"
                $msg = "Backing up $siteCollectionUrl to $path\$filename. "
                Write-Verbose $msg
                Write-Log -Message $msg
                Backup-SPSite -Identity $site -Path "$path\$filename" -Force

                $success = $true
                $msg = "$siteCollectionUrl backed up to $path\$filename"
                Write-Verbose $msg
                Write-Log -Message $msg -Type SUCCESS
            }
        }
        catch [System.Management.Automation.CommandNotFoundException]{
            $msg = "There was an issue Backing up $siteCollectionUrl to $path\$filename. "
            $msg += $_.Exception.Message
            $MSG += "This issue could be caused due to the SharePoint PowerShell Add-in not being loaded before using the module"
            Write-Verbose $msg
            Write-Log -Message $msg -Severity 3 -Type ERROR
        }
        catch {
            $msg = "There was an issue Backing up $siteCollectionUrl to $path\$filename."
            $msg += $_.Exception.Message
            Write-Verbose $msg
            Write-Log -Message $msg -Severity 3 -Type ERROR
        }
        finally{
            if($unlockSiteAfterBackup){
                $success =  Set-TISSPSiteLockStatus -siteCollectionUrl $siteCollectionUrl -lockStatus Unlock
            }

            $success
        }
    }
}