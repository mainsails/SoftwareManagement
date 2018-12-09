Function Remove-LoggedOnUser {
    <#
    .SYNOPSIS
        Remove LoggedOnUser
    .DESCRIPTION
        Remove LoggedOnUser
    .PARAMETER ComputerName
        Specifies the computer
    .PARAMETER UserName
        Specifies the username
    .EXAMPLE
        Remove-LoggedOnUser
    .NOTES
        CURRENTLY REMOVING ALL USERS : REWORK REQUIRED
    #>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false)]
        [string]$ComputerName = $env:ComputerName,
        [Parameter(Mandatory=$false)]
        [string]$UserName
    )

    Begin {
        # Verbose Logging
        [string]$CmdletName  = $MyInvocation.MyCommand.Name
        [string]$CmdletParam = $PSBoundParameters | Format-Table -Property @{ Label = 'Parameter'; Expression = { "[-$($_.Key)]" } }, @{ Label = 'Value'; Expression = { $_.Value }; Alignment = 'Left' } -AutoSize -Wrap | Out-String
        Write-Verbose -Message "##### Calling : [$CmdletName]"
    }
    Process {
        Try {
            Write-Verbose -Message "Get session information for all logged on users on [$ComputerName]"
            $SessionInfo = Write-Output -InputObject ([PSSM.QueryUser]::GetUserSessionInfo("$ComputerName"))
            Foreach ($Session in $SessionInfo) {
                Write-Verbose -Message "Logging off User : [$($Session.UserName)] from Computer : [$($Session.ComputerName)] by SessionID : [$($Session.SessionId)]"
                Start-EXE -Path "$env:SystemRoot\System32\LOGOFF.exe" -Parameters "$($Session.SessionId) /SERVER:$($Session.ComputerName)"
            }
        }
        Catch {
            Write-Warning -Message "Failed to get session information for logged on users on [$ComputerName]"
        }
    }
    End {
        # Verbose Logging
        Write-Verbose -Message "##### Ending : [$CmdletName]"
    }
}