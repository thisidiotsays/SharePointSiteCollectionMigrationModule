Function Add-TISSharePointAddIn{
    <#
    .SYNOPSIS
    Adds the SharePoint PowerShell Add-in

    .DESCRIPTION
    Long description

    .EXAMPLE
    An example

    .NOTES
    General notes
    #>

    [CmdletBinding()]
    Param()

    Write-Verbose "Testing to add SharePoint Snapin"
    if ($null -eq (Get-PSSnapin -Name Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue)){
        Add-PSSnapin Microsoft.SharePoint.PowerShell
    }
}