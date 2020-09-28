# Convert DateTime to Large Integer Date (AD computed)
function ConvertTo-LargeDate {
    param(
        [Parameter()]
        [DateTime]$Date = $(Get-Date),

        [Parameter()]
        [Int]$Days = 0
    )

    # Manipulate the converted date as required
    $Date = $Date.AddDays($Days)

    return $Date.ToFileTime()
}

# Convert Large Integer Date (AD computed) to DateTime
function ConvertFrom-LargeDate {
    param(
        [Parameter(Mandatory = $true)]
        $Date,

        [Parameter()]
        [Int]$Days = 0
    )

    $Date = [DateTime]::FromFileTime($Date)

    # Manipulate the converted date as required
    $Date = $Date.AddDays($Days)

    return $Date
}

# Render templates using f strings
function Expand-Template {
    param(
        [Parameter(Mandatory = $true)]
        [String]$Template,
        
        [Parameter(Mandatory = $true)]
        [String[]]$Values
    )

    if (Test-Path $Template) {
        $Content = (Get-Content -Path $Template -Raw) -f $Values

        return $Content
    }

    return
}

# Leverage the .NET class to log for PS Core compatibility
function New-EventLogMessage {
    param(
        [Parameter()]
        [String]$ComputerName = $($env:ComputerName),

        [Parameter()]
        [String]$EventID = 1,

        [Parameter()]
        [String]$EventLog = 'Password Reminder',

        [Parameter()]
        [String]$EventSource = 'Password Reminder',

        [Parameter()]
        [String]$EventType = 'Information',

        [Parameter(Mandatory = $true)]
        [String]$EventMessage
    )

    # This script may need to be executed as administartor the first time
    $e = New-Object System.Diagnostics.Eventlog(
        $EventLog,
        $ComputerName,
        $EventSource
    )

    $e.WriteEntry(
        $EventMessage,
        $EventType,
        $EventID
    )

    return
}

# Abstraction of Send-MailMessage for terseness
function Send-Email {
    param(
        [Parameter()]
        [String]$MailServer = 'YourSMTPServer.YourDomain.com',

        [Parameter()]
        [String]$MailFrom = 'YourAddress@YourDomain.com',

        [Parameter()]
        [String]$MailPriority = 'High',

        [Parameter(Mandatory = $true)]
        [String]$MailBody,

        [Parameter(Mandatory = $true)]
        [String]$MailSubject,

        [Parameter(Mandatory = $true)]
        [String]$MailTo
    )

    Send-MailMessage `
        -SmtpServer $MailServer `
        -From $MailFrom `
        -To $MailTo `
        -Subject $MailSubject `
        -Body $MailBody `
        -BodyAsHTML `
        -Priority $MailPriority `
        -WarningAction Ignore

    return
}