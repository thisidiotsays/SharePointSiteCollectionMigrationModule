Function Start-TISSPGradualDeleteTimerJob{
    <#
    .SYNOPSIS
    Runs the "Gradual Delete" SharePoint timer job(s). These jobs complete the deletion of site collections from a content databases either after a site collection has been deleted or moved.

    .DESCRIPTION
    ***SHOULDN'T BE RUN ON A PRODUCTION ENVIRONMENT - USEFUL IN A DEV ENV. IF MOVING SITE COLLECTIONS BACK AND FORTH BETWEEN DATABASES***

    After moving or deleting a site collection the contents of that site collection will remain in the content database until the "Gradual Site Delete" timer job associated with the Web Application has been ran.
    This can prevent and delay moving a site collection back to its original content database during testing.

    The command can be run with zero or more web application display names specified. If no name is specified then all the jobs for all web applications will be run.

    The Gradual Site Delete Timer job is normally ran at some point between 10pm and 2am as depending on the size of the site collection being deleted can impact SQL performance.

    .PARAMETER webApplicationName
    The display name of the web application(s) you want to run the timer job for

    .EXAMPLE
    Start-TISSPGradualDeleteTimerJob

    This will run the "Gradual Site Delete" Timer Jobs for every web application. You will be prompted to confirm before this runs.

    .EXAMPLE
    Start-TISSPGradualDeleteTimerJob -webApplicationName "Intranet","my"

    This will run the "Gradual Site Delete" Timer Jobs for the Intranet and My web applications. You will be prompted to confirm before this runs.

    .EXAMPLE
    Start-TISSPGradualDeleteTimerJob -webApplicationName "Intranet","my" -confirm:$false

    This will run the "Gradual Site Delete" Timer Jobs for the Intranet and My web applications. You will NOT be prompted to confirm before this runs.

    .NOTES
    General notes
    #>

    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact="High"
    )]
    Param(
        [string[]]$webApplicationName
    )

    Begin{
        if([string]::IsNullOrEmpty($webApplicationName)){
            $msg = "All Web Applications"
        } else {
            $msg = $webApplicationName
        }
    }

    Process {
        function Wait-forJob{
            Param(
                [Microsoft.SharePoint.Administration.SPContentDatabaseJobDefinition]$timerJob
            )

            $jobName = $timerJob.DisplayName + " - " + $timerJob.WebApplication.Name
            Write-Verbose "Entering Wait-ForJob for $jobName"

            $lastRunTime = $timerJob.LastRunTime
            Write-Verbose "$jobName - last run of $lastRunTime"

            Write-Verbose "Starting $jobName"
            Start-SPTimerJob $timerJob -Verbose:$false

            While($lastRunTime -eq $timerJob.LastRunTime){
                Start-Sleep -Seconds 2
                $timerJob = Get-SPTimerJob $timerJob -Verbose:$false
            }

            Write-Verbose "$jobName executed successfully at $($timerJob.LastRunTime)"
        }

        if($PSCmdlet.ShouldProcess($msg,"Run Gradual Site Delete Timer Job")){
            if([string]::IsNullOrEmpty($webApplicationName)){
                $jobs = Get-SPTimerJob | Where-Object DisplayName -eq "Gradual Site Delete"

                foreach($j in $jobs){
                    Wait-forJob $j
                }
            } else {
                foreach($wa in $webApplicationName){
                    $jobs = Get-SPTimerJob | Where-Object {$_.DisplayName -eq "Gradual Site Delete" -and $_.WebApplication.Name -eq $wa}

                    foreach($j in $jobs){
                        Wait-forJob $j
                    }
                }
            }
        }
    }
}
