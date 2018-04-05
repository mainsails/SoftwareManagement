Function Get-LocalUsers {
    <#
    .SYNOPSIS
        Get local user account details on local and remote systems
    .DESCRIPTION
        Get local user account details on local and remote systems using ADSI
        Returned object properties are as follows :
          ComputerName        : Computer Name
          UserName            : Account Name
          Description         : Account Description
          SID                 : Account SID
          ProfilePath         : Local Profile Path
          PasswordAge         : Password Age
          LastLogin           : Last Login Time
          UserFlags           : Account Flags : https://msdn.microsoft.com/en-us/library/aa772300(v=vs.85).aspx
          MinPasswordLength   : Minimum Password Length
          MinPasswordAge      : Minimum Password Age
          MaxPasswordAge      : Maximum Password Age
          BadPasswordAttempts : Bad Password Attempt Count
          MaxBadPasswords     : Maximum Bad Password Allowance
    .PARAMETER ComputerName
        Specifies the computers to query. The default is the local computer
    .EXAMPLE
        Get-LocalUsers
        Get local account details for the local computer
    .EXAMPLE
        'Computer1','Computer2' | Get-LocalUsers
        Get local account details for Computer1 and Computer2
    .LINK
        Get-UserProfiles
    .LINK
        https://msdn.microsoft.com/en-us/library/aa772300(v=vs.85).aspx
    #>

    [Cmdletbinding()]
    Param(
        [Parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [String[]]$ComputerName = $env:COMPUTERNAME
    )

    Begin {
        # Verbose Logging
        [string]$CmdletName  = $MyInvocation.MyCommand.Name
        [string]$CmdletParam = $PSBoundParameters | Format-Table -Property @{ Label = 'Parameter'; Expression = { "[-$($_.Key)]" } }, @{ Label = 'Value'; Expression = { $_.Value }; Alignment = 'Left' } -AutoSize -Wrap | Out-String
        Write-Verbose -Message "##### Calling : [$CmdletName]"

        # Helper function to convert ADSI returned ObjectSid from a byte array to the string representation of a SID
        Function ConvertTo-SID {
            Param([byte[]]$BinarySID)
            (New-Object System.Security.Principal.SecurityIdentifier($BinarySID,0)).Value
        }

        # Helper function to convert ADSI returned UserFlag to human veadable values
        Function Convert-UserFlag {
            Param ($UserFlag)
            $List = New-Object System.Collections.ArrayList
            Switch ($UserFlag) {
                ($UserFlag -BOR 0x0001)     { [void]$List.Add('SCRIPT') }
                ($UserFlag -BOR 0x0002)     { [void]$List.Add('ACCOUNTDISABLE') }
                ($UserFlag -BOR 0x0008)     { [void]$List.Add('HOMEDIR_REQUIRED') }
                ($UserFlag -BOR 0x0010)     { [void]$List.Add('LOCKOUT') }
                ($UserFlag -BOR 0x0020)     { [void]$List.Add('PASSWD_NOTREQD') }
                ($UserFlag -BOR 0x0040)     { [void]$List.Add('PASSWD_CANT_CHANGE') }
                ($UserFlag -BOR 0x0080)     { [void]$List.Add('ENCRYPTED_TEXT_PWD_ALLOWED') }
                ($UserFlag -BOR 0x0100)     { [void]$List.Add('TEMP_DUPLICATE_ACCOUNT') }
                ($UserFlag -BOR 0x0200)     { [void]$List.Add('NORMAL_ACCOUNT') }
                ($UserFlag -BOR 0x0800)     { [void]$List.Add('INTERDOMAIN_TRUST_ACCOUNT') }
                ($UserFlag -BOR 0x1000)     { [void]$List.Add('WORKSTATION_TRUST_ACCOUNT') }
                ($UserFlag -BOR 0x2000)     { [void]$List.Add('SERVER_TRUST_ACCOUNT') }
                ($UserFlag -BOR 0x10000)    { [void]$List.Add('DONT_EXPIRE_PASSWORD') }
                ($UserFlag -BOR 0x20000)    { [void]$List.Add('MNS_LOGON_ACCOUNT') }
                ($UserFlag -BOR 0x40000)    { [void]$List.Add('SMARTCARD_REQUIRED') }
                ($UserFlag -BOR 0x80000)    { [void]$List.Add('TRUSTED_FOR_DELEGATION') }
                ($UserFlag -BOR 0x100000)   { [void]$List.Add('NOT_DELEGATED') }
                ($UserFlag -BOR 0x200000)   { [void]$List.Add('USE_DES_KEY_ONLY') }
                ($UserFlag -BOR 0x400000)   { [void]$List.Add('DONT_REQ_PREAUTH') }
                ($UserFlag -BOR 0x800000)   { [void]$List.Add('PASSWORD_EXPIRED') }
                ($UserFlag -BOR 0x1000000)  { [void]$List.Add('TRUSTED_TO_AUTH_FOR_DELEGATION') }
                ($UserFlag -BOR 0x04000000) { [void]$List.Add('PARTIAL_SECRETS_ACCOUNT') }
            }
            $List  -join ', '
        }

    }
    Process {
        ForEach ($Computer in $Computername) {
            # ADSI Query machine
            $ADSI = [ADSI]"WinNT://$Computer"
            # Build PSCustomObject of results
            $ADSI.Children | Where-Object -FilterScript { $_.SchemaClassName -eq 'User' } | ForEach {
                [PSCustomObject]@{
                    ComputerName        = $Computer
                    UserName            = $_.Name[0]
                    Description         = $_.Description[0]
                    SID                 = ConvertTo-SID -BinarySID $_.ObjectSID[0]
                    ProfilePath         = Get-UserProfiles -ExcludeSystemProfiles $false | Where-Object -Property 'SID' -EQ (ConvertTo-SID -BinarySID $_.ObjectSID[0]) | Select-Object -ExpandProperty 'ProfilePath'
                    PasswordAge         = [math]::Round($_.PasswordAge[0]/86400)
                    LastLogin           = If ($_.LastLogin[0] -is [datetime]) { $_.LastLogin[0] } Else { 'Never logged on' }
                    UserFlags           = Convert-UserFlag -UserFlag $_.UserFlags[0]
                    MinPasswordLength   = $_.MinPasswordLength[0]
                    MinPasswordAge      = [math]::Round($_.MinPasswordAge[0]/86400)
                    MaxPasswordAge      = [math]::Round($_.MaxPasswordAge[0]/86400)
                    BadPasswordAttempts = $_.BadPasswordAttempts[0]
                    MaxBadPasswords     = $_.MaxBadPasswordsAllowed[0]
                }
            }
        }
    }
    End {
        # Verbose Logging
        Write-Verbose -Message "##### Ending : [$CmdletName]"
    }
}