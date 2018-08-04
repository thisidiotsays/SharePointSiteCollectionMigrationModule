$date = (Get-date).ToString("yyyyMMdd")
$backupPath = "M:\SPSiteBackups"
$logFile = "$env:LOCALAPPDATA\$($date)_SiteMoveLog.log"

Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

$siteCollections = Import-Csv C:\PSScripts\sitestobemoved.csv

#Track the number of errors
$errorCount = 0

#Backup Sites - Will only pass on site collections which have not had any issues
$backupErrorCount = 0
$successfulBackupSites = foreach($s in $siteCollections){
    $result = Backup-TISSPSiteToDisk -siteCollectionUrl $s.Url -path $backupPath -unlockSiteAfterBackup $false
    If($result -eq $false){
        $backupErrorCount += 1
    } else {
        $s
    }
}

#This would mean that no sites were successfully backed up
If($successfulBackupSites.Count -gt 0){

    #Move Sites - Only moves sites which have been successfully backed up
    $siteMoveErrorCount = 0
    $successfulMovedSites = foreach($sbs in $successfulBackupSites){
        $result = Move-TISSPSite -siteCollectionUrl $sbs.Url -contentDatabaseName $sbs.contentDatabase -SuppressSPSiteMoveConfirm

        If($result -eq $false){
            $siteMoveErrorCount += 1
        } else {
            $sbs
        }
    }

    $iisRestartSuccess = Restart-TISSPIISAllServers
    
    $siteUnlockErrorCount = 0
    if($iisRestartSuccess){
        $successfulUnlockedSites = foreach($sms in $successfulMovedSites){
            $result = Set-TISSPSiteLockStatus -siteCollectionUrl $sms.Url -lockStatus Unlock

            If($result -eq $false){
                $siteUnlockErrorCount += 1
            } else {
                $sbs
            }
        }
    }        
}

ISE $logFile

<#
Start-TISSPGradualDeleteTimerJob -verbose
#>