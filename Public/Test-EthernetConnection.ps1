Function Test-EthernetConnection {
    <#
    .SYNOPSIS
        Tests for an active local wired network connection
    .DESCRIPTION
        Tests for an active local network connection, excluding wireless and virtual network adapters by querying the Win32_NetworkAdapter WMI class
    .EXAMPLE
        Test-EthernetConnection
    #>
    [CmdletBinding()]
    Param ()

    Begin {
        # Verbose Logging
        [string]$CmdletName  = $MyInvocation.MyCommand.Name
        [string]$CmdletParam = $PSBoundParameters | Format-Table -Property @{ Label = 'Parameter'; Expression = { "[-$($_.Key)]" } }, @{ Label = 'Value'; Expression = { $_.Value }; Alignment = 'Left' } -AutoSize -Wrap | Out-String
        Write-Verbose -Message "##### Calling : [$CmdletName]"
    }
    Process {
        Write-Verbose -Message 'Check if system is using a wired network connection'
        [psobject[]]$NetworkConnected = Get-WmiObject -Class 'Win32_NetworkAdapter' | Where-Object -FilterScript { ($_.NetConnectionStatus -eq 2) -and ($_.NetConnectionID -match 'Local' -or $_.NetConnectionID -match 'Ethernet') -and ($_.NetConnectionID -notmatch 'Wireless') -and ($_.Name -notmatch 'Virtual') } -ErrorAction 'SilentlyContinue'
        [boolean]$Connected = $false
        If ($NetworkConnected) {
            Write-Verbose -Message 'Wired network connection found'
            [boolean]$Connected = $true
        }
        Else {
            Write-Verbose -Message 'Wired network connection not found'
        }
        Write-Output -InputObject $Connected
    }
    End {
        # Verbose Logging
        Write-Verbose -Message "##### Ending : [$CmdletName]"
    }
}