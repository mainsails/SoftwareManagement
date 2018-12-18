Function Remove-LoggedOnUser {
    <#
    .SYNOPSIS
        Removes logged on user(s).
    .DESCRIPTION
        Queries a computer for all logged in users and logs them out as required.
    .PARAMETER ComputerName
        Specifies the computer to query for session details. The default is the local computer.
    .PARAMETER UserName
        Specifies a user name or names to log off.
    .PARAMETER All
        Specifies that all users will be logged off.
    .EXAMPLE
        Remove-LoggedOnUser -UserName 'UserA','UserB'
        Logs off the two specified users from the local computer.
    .EXAMPLE
        Remove-LoggedOnUser -ComputerName 'Computer1' -All
        Logs off all users from the specified computer.
    .LINK
        Get-LoggedOnUser
    #>

    [CmdletBinding(DefaultParameterSetName='UserName')]
    Param (
        [Parameter(Mandatory=$false)]
        [string]$ComputerName = $env:ComputerName,
        [Parameter(ParameterSetName='UserName',Mandatory=$true)]
        [string[]]$UserName,
        [Parameter(ParameterSetName='All',Mandatory=$false)]
        [switch]$All
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
                If ($PSCmdlet.ParameterSetName -eq 'UserName') {
                    Foreach ($Session in $SessionInfo) {
                        If ($UserName -notcontains $Session.UserName) {
                            return
                        }
                    }
                }
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