# Functions to perform heavy-lifting
. ".\include.ps1"

# Expiration threshold in days
$ExpiryThreshold = 7

# Threshold for last logon in (negative) days
$LogonThreshold = -90

# Email subject template
$SubjectTemplate = ".\Templates\reminder_subject.txt"

# Email body template
$BodyTemplate = ".\Templates\reminder_body.html"

# Event log template
$EventTemplate = ".\Templates\eventlog_template.txt"

#-----------------------Do Not Edit Below------------------------#

# Last logon threshold in Larger Integer Date
$LogonTimeComputed = ConvertTo-LargeDate -Days $LogonThreshold

# Splat ADUser for readability
$ADUser = @{
    Filter = 'Enabled -eq $true -and PasswordNeverExpires -eq $false -and lastLogon -ge {0}' -f $LogonTimeComputed
    Properties = (
        'mail',
        'personalEmail',
        'lastLogon',
        'msDS-UserPasswordExpiryTimeComputed'
    )
    Searchbase = "OU=Domain Users,DC=clinic,DC=com"
}



# Splat-like Select-Object for improved readability
$ADUserProperties = @(
    'mail',
    'personalEmail',
    'samAccountName'
    @{
        Name = "ExpiryDays"
        Expression = {
            (New-TimeSpan `
                -Start $(Get-Date).Date `
                -End $(ConvertFrom-LargeDate -Date $_."msDS-UserPasswordExpiryTimeComputed")
            ).Days
        }
    }
)

# Find users whose password has not yet expired within the defined threshold
$Users = Get-ADUser @ADUser | Select-Object $ADUserProperties | Where-Object { $_.ExpiryDays -le $ExpiryThreshold -and $_.ExpiryDays -ge 1 }

# Iterate users
$Users | ForEach-Object {
    # Ensure the user has an email address
    if ($_.mail -ne $null -or $_.personalEmail -ne $null) {

        # mail is the preferred address with personalEmail for fallback
        $Recipient = ($_.mail -ne $null) ? $_.mail : $_.personalEmail

        # Expand mail templates
        $Subject = Expand-Template -Template $SubjectTemplate -Values $_.ExpiryDays
        $Body = Expand-Template -Template $BodyTemplate -Values $_.ExpiryDays

        # Expand event log template
        $Log = Expand-Template -Template $EventTemplate -Values $_.samAccountName, $_.ExpiryDays, $Recipient
        
        # Generate email & event log entry asynchronously per user
        [void](Start-Job -InitializationScript { . ".\Include.ps1" } -Scriptblock {

            # Send the end-user email
            Send-Email `
                -MailTo $args[0] `
                -MailSubject $args[1] `
                -MailBody $args[2]

            # Create event log entry
            New-EventLogMessage -EventMessage $args[3]

        } -ArgumentList $Recipient, $Subject, $Body, $Log)
    }
}

#Wait for the children to complete
Get-Job | Wait-Job