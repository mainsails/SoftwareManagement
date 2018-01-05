Function Set-PowerPlan {
    <#
    .SYNOPSIS
        Set the Power Plan for a machine
    .DESCRIPTION
        Set the Power Plan for a machine
    .PARAMETER Name
        Power Plan Name
    .EXAMPLE
        Set-PowerPlan -Name 'High performance'
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
        $PowerPlan = Get-PowerPlan -Name $Name
        If ($PowerPlan) {
            If ($PowerPlan.IsActive -eq $true) {
                Write-Warning -Message "Power Plan [$Name] is already active"
                Continue
            }
            Try {
                $PowerPlan | Invoke-CimMethod -MethodName Activate | Out-Null
                Write-Verbose -Message "Power Plan set to [$($PowerPlan.ElementName)]"
            }
            Catch {
                Write-Error $_.Exception.Message
            }
        }
    }
    End {
        # Verbose Logging
        Write-Verbose -Message "##### Ending : [$CmdletName]"
    }
}