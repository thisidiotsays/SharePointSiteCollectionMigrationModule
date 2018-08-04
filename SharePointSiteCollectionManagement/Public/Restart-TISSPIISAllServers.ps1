Function Restart-TISSPIISAllServers{
    <#
    .SYNOPSIS
    Restart IIS on all servers in the farm

    .DESCRIPTION
    Uses the Get-SPServer command of the SharePoint pssnapin to get all the servers in the farm. An IISReset is run on all the servers and the status checked for success.

    .EXAMPLE
    Restart-TISSPIISAllServers

    This will restart IIS on all servers in the farm

    .NOTES
    General notes
    #>

    [CmdletBinding()]
    Param()

    Begin{
        $success = $false
    }

    Process{
        try {
            $msg = "Restarting the IIS Service on all servers in the farm"
            Write-Verbose $msg
            Write-Log -Message $msg

            $spservers = Get-SPServer | Where-Object Role -ne "Invalid" | Select-Object -ExpandProperty Address

            foreach($s in $spservers){
                $msg = "Attempting IIS Service restart on $s"
                Write-Verbose $msg
                Write-Log -Message $msg
                $status = Invoke-Command -ComputerName $s -ScriptBlock {iisreset}

                $errCount = 0

                if(($status | Where-Object {$_ -eq "Internet services successfully restarted"}).count -eq 1){
                    $msg = "IIS Service successfully restart on $s"
                    Write-Verbose $msg
                    Write-Log -Message $msg -Type SUCCESS
                } else {
                    $msg = "Error - There was an restarting the IIS Service on $s"
                    $msg += $status
                    Write-Verbose $msg
                    Write-Log -Message $msg -Severity 3 -Type ERROR

                    $errCount +=1
                }
            }

            if($errCount -eq 0){
                $success = $true
            } else {
                $success = $false
            }
        }
        catch {
                $msg = "Something went wrong"
                Write-Verbose $msg
                Write-Log -Message $msg -Severity 3 -Type ERROR

                $success = $false
        }
        finally {
            $success
        }
    }
}