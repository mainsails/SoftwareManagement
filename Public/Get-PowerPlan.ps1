Function Get-PowerPlan {
    <#
    .SYNOPSIS
        Retrieves the Power Plan from a machine
    .DESCRIPTION
        Retrieves the Power Plan from a machine
    .PARAMETER Name
        Power Plan Name
    .EXAMPLE
        Get-PowerPlan -Name 'High performance'
    #>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false)]
        [ValidateSet('Balanced','High performance','Power saver')]
        [string]$Name
    )

    Begin {
        # Verbose Logging
        [string]$CmdletName  = $MyInvocation.MyCommand.Name
        [string]$CmdletParam = $PSBoundParameters | Format-Table -Property @{ Label = 'Parameter'; Expression = { "[-$($_.Key)]" } }, @{ Label = 'Value'; Expression = { $_.Value }; Alignment = 'Left' } -AutoSize -Wrap | Out-String
        Write-Verbose -Message "##### Calling : [$CmdletName]"
    }
    Process {
        $CimInstanceArguments = @{
            Name   = 'root\cimv2\power'
            Class  = 'Win32_PowerPlan'
        }
        If ($Name) {
            $CimInstanceArguments += @{ Filter = "ElementName = '$Name'" }
        }
        Try {
            $PowerPlan = Get-CimInstance @CimInstanceArguments
        }
        Catch {
            Write-Error $_.Exception.Message
        }
        Write-Output -InputObject $PowerPlan
    }
    End {
        # Verbose Logging
        Write-Verbose -Message "##### Ending : [$CmdletName]"
    }
}