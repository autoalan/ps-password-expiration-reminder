## PowerShell Password Expiration Reminder
This script is written in Powershell 7.0 with the ActiveDirectory module being the only dependency outside of .NET, which is used to write information to the event log. All templates using for communicationa and logging reside in the templates directory. While it could benefit from refactoring to better address user customization, it's solid and could be made public with minimal effort. 

### include.ps1
Update the MailServer & MailFrom variables. 
````
96: [String]$MailServer = 'YourSMTPServer.YourDomain.com',
99: [String]$MailFrom = 'YourAddress@YourDomain.com',
````

### reminder.ps1
Update ExpiryThreshold & LogonThreshold as appropriate.
````
4: # Expiration threshold in day
5: $ExpiryThreshold = 7
6:
7: # Threshold for last logon in (negative) days
8: $LogonThreshold = -90
````

LogonThreshold can be used to exclude enabled accounts that have been inactive for long periods of time.
