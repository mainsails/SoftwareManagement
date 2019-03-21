Function Get-FileLockProcess {
    <#
    .SYNOPSIS
        Check which local process is locking a file.
    .DESCRIPTION
        Get-FileLockProcess takes a path to a file and returns a System.Collections.Generic.List of System.Diagnostic.Process objects.
    .PARAMETER Path
        This parameter takes a string that represents a full path to a file.
    .OUTPUTS
        System.Diagnostics.Process
    .EXAMPLE
        Get-FileLockProcess -Path "$HOME\Documents\Spreadsheet.csv"

        Handles  NPM(K)    PM(K)      WS(K)     CPU(s)     Id  SI ProcessName
        -------  ------    -----      -----     ------     --  -- -----------
           1235      74    94640     131284       5.13  30192   1 EXCEL

        This command queries the specified file and displays the locking process object.
    .EXAMPLE
        Get-FileLockProcess -Path "C:\Work\Document.odt" | Stop-Process -Force

        This command queries the specified file and forcefully terminates the locking process(es).
    #>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [ValidateScript({ Test-Path -Path $_ })]
        [string]$Path
    )

    Begin {
        # Verbose Logging
        [string]$CmdletName  = $MyInvocation.MyCommand.Name
        [string]$CmdletParam = $PSBoundParameters | Format-Table -Property @{ Label = 'Parameter'; Expression = { "[-$($_.Key)]" } }, @{ Label = 'Value'; Expression = { $_.Value }; Alignment = 'Left' } -AutoSize -Wrap | Out-String
        Write-Verbose -Message "##### Calling : [$CmdletName]"
    }

    Process {
        Try {
            Write-Verbose -Message "Check for file locking process on : [$Path]"
            $Result = [PSSM.FileLock]::WhoIsLocking($Path)
            Write-Output -InputObject $Result
        }
        Catch {
            Write-Warning -Message $_.Exception.Message
        }
    }
    End {
        # Verbose Logging
        Write-Verbose -Message "##### Ending : [$CmdletName]"
    }
}