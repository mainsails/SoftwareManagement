Function Get-UserProfiles {
    <#
    .SYNOPSIS
        Get the User Profile Path, User Account SID, and the User Account Name for all users that log onto the machine (including the Default User)
    .DESCRIPTION
        Get the User Profile Path, User Account SID, and the User Account Name for all users that log onto the machine (including the Default User)
    .PARAMETER ExcludeNTAccount
        Specify NT account names in <domain>\<username> format to exclude from the list of user profiles
    .PARAMETER ExcludeSystemProfiles
        Exclude system profiles: SYSTEM, LOCAL SERVICE, NETWORK SERVICE. Default is: $true
    .PARAMETER ExcludeDefaultUser
        Exclude the Default User. Default is: $false
    .EXAMPLE
        Get-UserProfiles
        Returns the following properties for each user profile on the system: NTAccount, SID, ProfilePath
    .EXAMPLE
        Get-UserProfiles -ExcludeNTAccount '<domain>\UserName','<domain>\AnotherUserName'
    .EXAMPLE
        [string[]]$ProfilePaths = Get-UserProfiles | Select-Object -ExpandProperty 'ProfilePath'
        Returns the user profile path for each user on the system. This information can then be used to make modifications under the user profile on the filesystem
    #>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string[]]$ExcludeNTAccount,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [boolean]$ExcludeSystemProfiles = $true,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [switch]$ExcludeDefaultUser = $false
    )

    Begin {
        # Verbose Logging
        [string]$CmdletName  = $MyInvocation.MyCommand.Name
        [string]$CmdletParam = $PSBoundParameters | Format-Table -Property @{ Label = 'Parameter'; Expression = { "[-$($_.Key)]" } }, @{ Label = 'Value'; Expression = { $_.Value }; Alignment = 'Left' } -AutoSize -Wrap | Out-String
        Write-Verbose -Message "##### Calling : [$CmdletName]"
    }
    Process {
        Try {
            Write-Verbose -Message 'Get the User Profile Path, User Account SID, and the User Account Name for all users that log onto the machine'

            # Get the User Profile Path, User Account SID and the User Account Name for all users that log onto the machine
            [string]$UserProfileListRegKey = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList'
            [psobject[]]$UserProfiles = Get-ChildItem -LiteralPath $UserProfileListRegKey -ErrorAction 'Stop' |
            ForEach-Object {
                Get-ItemProperty -LiteralPath $_.PSPath -ErrorAction 'Stop' | Where-Object { ($_.ProfileImagePath) } |
                Select-Object @{ Label = 'NTAccount'; Expression = { $(ConvertTo-NTAccountOrSID -SID $_.PSChildName).Value } }, @{ Label = 'SID'; Expression = { $_.PSChildName } }, @{ Label = 'ProfilePath'; Expression = { $_.ProfileImagePath } }
            }
            If ($ExcludeSystemProfiles) {
                [string[]]$SystemProfiles = 'S-1-5-18', 'S-1-5-19', 'S-1-5-20'
                [psobject[]]$UserProfiles = $UserProfiles | Where-Object { $SystemProfiles -notcontains $_.SID }
            }
            If ($ExcludeNTAccount) {
                [psobject[]]$UserProfiles = $UserProfiles | Where-Object { $ExcludeNTAccount -notcontains $_.NTAccount }
            }

            # Find the path to the Default User profile
            If (-not $ExcludeDefaultUser) {
                [string]$UserProfilesDirectory = Get-ItemProperty -LiteralPath $UserProfileListRegKey -Name 'ProfilesDirectory' -ErrorAction 'Stop' | Select-Object -ExpandProperty 'ProfilesDirectory'

                If ([Environment]::OSVersion.Version.Major -gt 5) {
                    # Path to Default User Profile directory on Windows Vista or higher: By default, C:\Users\Default
                    [string]$DefaultUserProfileDirectory = Get-ItemProperty -LiteralPath $UserProfileListRegKey -Name 'Default' -ErrorAction 'Stop' | Select-Object -ExpandProperty 'Default'
                }

                # Create a custom object for the Default User profile since it is not an actual account
                [psobject]$DefaultUserProfile = New-Object -TypeName 'PSObject' -Property @{
                    NTAccount = 'Default User'
                    SID = 'S-1-5-21-Default-User'
                    ProfilePath = $DefaultUserProfileDirectory
                }

                # Add the Default User custom object to the User Profile list
                $UserProfiles += $DefaultUserProfile
            }

            Write-Output -InputObject $UserProfiles
        }
        Catch {
            Write-Warning -Message 'Failed to create a custom object representing all user profiles on the machine'
        }
    }
    End {
        # Verbose Logging
        Write-Verbose -Message "##### Ending : [$CmdletName]"
    }
}