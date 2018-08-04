Function Test-TISSPSiteMoveInfo{
    <#
    .SYNOPSIS
    Tests the data for the site moves.

    .DESCRIPTION
    Imports the data being used to specify the sites which are being moved and checks the following:
    - Checks the specified URL corresponds to an existing site collection
    - Checks the specified target content database exists
    - If the site exists, checks that the desired target content database doesn't match the sites current content database.
    - Checks that the specified target content database is associated with the same web application as the site collection. You can only move site collections between content databases associated with the same web application.

    The tests will report whether the sites passed or failed the tests.

    The data which is being imported must provide objects which have a Url and Content Database property.

    .PARAMETER SitesToMove
    A collection of site objects which must have properties called Url and ContentDatabase.

    .EXAMPLE
    Test-TISSPSiteMoveInfo -SitesToMove (Import-Csv C:\PSScripts\sitestobemoved.csv) | ft -AutoSize

    UrlPassedIn                                           TargetContentDatabase          SiteFound TargetDBExists CurrentSiteDatabase           TargetCurrentDBMatch TargetdbInSameWebApp PassedTests
    -----------                                           ---------------------          --------- -------------- -------------------           -------------------- -------------------- -----------
    http://customers.domain.com/customer/ProganProject    WSS_Content_Customers3         Yes       Yes            WSS_Content_Customers         No                   Yes                  Yes        
    http://customers.domain.com/customer/PadThinkltd      WSS_Content_Customers4         Yes       Yes            WSS_Content_Customers         No                   Yes                  Yes        
    http://intranet.domain.com                            SharePoint_Intranet_ContentDB2 Yes       Yes            SharePoint_Intranet_ContentDB No                   Yes                  Yes        
    http://this.doesnotexist.com                          WSS_Content_Customers4         No        Yes            N/A                           No                   No                   No     

    This example imports data from a CSV which has two columns Url and ContentDatabase. The first three sites pass all the tests. The last site does not pass as the URL does not exist.

    .EXAMPLE
    Test-TISSPSiteMoveInfo -SitesToMove (Import-Csv C:\PSScripts\sitestobemoved.csv) | Where-Object PassedTests -eq "No"

    This example will only return the sites which did not pass all the sites

    .NOTES
    General notes
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [object[]]$SitesToMove
    )
    Write-Verbose "Number of sites to test $($SitesToMove.Count)"
    if($SitesToMove.Count -gt 0){
        if(($SitesToMove[0].PSObject.Properties.name -match "Url") -and ($SitesToMove[0].PSObject.Properties.name -match "ContentDatabase")){
            $totalErrors = 0

            $results = foreach($s in $SitesToMove){
                $siteObject = [PSCustomObject]@{
                    UrlPassedIn = $s.Url
                    TargetContentDatabase = $s.ContentDatabase
                }

                #Ensure values are null for each loop
                $site = $null
                $contentdb = $null
                $errors = 0

                Write-Verbose "Checking if there is a site collection at $($s.Url)"
                try{
                    $site = Get-SPSite $s.Url -errorAction Stop
                    Write-Verbose "Site Collection $($s.Url) was found"
                    $SiteFound = "Yes"
                } catch {
                    Write-Verbose "Site Collection $($s.Url) not found"
                    $siteFound= "No"
                    $errors += 1
                }

                $siteObject | Add-Member -MemberType NoteProperty -Name "SiteFound" -Value $SiteFound

                Write-Verbose "Checking if the target content database $($s.ContentDatabase) exists for $($s.Url)"
                try{
                    $contentdb = Get-SPContentDatabase $s.ContentDatabase -errorAction Stop
                    Write-Verbose "Content database $($s.ContentDatabase) exists for $($s.Url)"
                    $DatabaseExists = "Yes"
                }catch{
                    Write-Verbose "Content database $($s.ContentDatabase) for $($s.Url) does not exist"
                    $DatabaseExists = "No"
                    $errors += 1
                }

                $siteObject | Add-Member -MemberType NoteProperty -Name "TargetDBExists" -Value $DatabaseExists

                #Get the current database which holds the site collection
                if($site){
                    $currentContentDatabase = $site.ContentDatabase.Name
                    Write-Verbose "The current content database for $($s.Url) is $currentContentDatabase"
                } else {
                    Write-Verbose "The current content database for $($s.Url) is N/A as site does not exist"
                    $currentContentDatabase = "N/A"
                    $errors += 1
                }

                $siteObject | Add-Member -MemberType NoteProperty -Name "CurrentSiteDatabase" -Value $currentContentDatabase

                #Check if the target and the current are the same
                if($contentdb){
                    if($s.ContentDatabase -eq $currentContentDatabase){
                        Write-Verbose "The current content database for $($s.Url) is $currentContentDatabase and matches the target database $($s.ContentDatabase)"
                        $targetAndCurrentDBMatch = "Yes"
                        $errors += 1
                    }else{
                        Write-Verbose "The current content database for $($s.Url) is $currentContentDatabase and does not match the target database $($s.ContentDatabase)"
                        $targetAndCurrentDBMatch = "No"
                    }
                } else {
                    Write-Verbose "Cannot check target and current databases match as $($s.Url) is N/A as site does not exist"
                    $targetAndCurrentDBMatch = "N/A"
                    $errors += 1
                }

                $siteObject | Add-Member -MemberType NoteProperty -Name "TargetCurrentDBMatch" -Value $targetAndCurrentDBMatch

                #Check target content database is part of same web application
                if($contentdb){
                    if($site.WebApplication.Url -eq $contentdb.WebApplication.Url){
                        Write-Verbose "The target content database $($contentdb.WebApplication.Url) for $($s.Url) is in the same web application)"
                        $dbInSameWebApp = "Yes"
                    }else{
                        Write-Verbose "The target content database $($contentdb.WebApplication.Url) for $($s.Url) is not in the same web application)"
                        $dbInSameWebApp = "No"
                        $errors += 1
                    }
                } else {
                    Write-Verbose "Cannot check web application for databases as $($s.Url) is N/A as site does not exist"
                    $dbInSameWebApp = "N/A"
                    $errors += 1
                }

                $siteObject | Add-Member -MemberType NoteProperty -Name "TargetdbInSameWebApp" -Value $dbInSameWebApp

                #Report if move will succeed
                if($errors -eq 0){
                    Write-Verbose "No errors found for moving $($s.Url) to $($s.contentDatabase)"
                    $PassedAllTests = "Yes"
                } else {
                    Write-Verbose "$errors errors found for moving $($s.Url) to $($s.contentDatabase). Review data."
                    $PassedAllTests = "No"
                    $totalErrors +=1
                }

                $siteObject | Add-Member -MemberType NoteProperty -Name "PassedTests" -Value $PassedAllTests

                $siteObject
            }

            $results

            if($totalErrors -eq 0){
                Write-Host "All the sites to be moved passed all the test. You should be good to go" -ForegroundColor Green
            } else {
                Write-Host "Some or all of the sites for migration had errors. Please check the data passed in." -ForegroundColor Yellow
            }
        } else {
            Write-Error "The data being passed in should have properties called Url and ContentDatabase"
        }
    } else {
        Write-Error "No sites were passed in"
    }
}