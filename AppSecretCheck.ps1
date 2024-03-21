#Azure App Registration Secret Expiration Report
#Gets all app secrets and sends an email report with ones that are about to expire

#Connect to Graph
Connect-MgGraph -ClientID "xxxxxxxxxxxxx" -TenantId "xxxxxxxxxxxxx" -CertificateThumbprint "xxxxxxxxxxxxx"

#Email report send to
$smtpServer = "mail.example.com"
$emailFrom = "noreply@example.com"
$mailsend = "you@example.com"

$allApps = Get-MgApplication -all
$allApps = $allApps | sort DisplayName
$date30 = (get-date).AddDays(30)
$date60 = (get-date).AddDays(60)
$dateNow = get-date

$notice = @()
$notice2 = @()
$timeremaining = @()
foreach ($app in $allApps) {
    $secretCheck = (Get-MgApplication -ApplicationId $app.Id).PasswordCredentials
    if ($secretCheck.EndDateTime) {
        if (($secretCheck.EndDateTime -le $date30) -and ($secretCheck.EndDateTime -ge $dateNow)) {
            $notice += $app | select @{Name='Name'; Expression = {$_.displayname}}
            $notice2 += $secretCheck | select @{Name='Expiration'; Expression = {$_.EndDateTime}}
            $timeremaining += $secretCheck.EndDateTime - $datenow | select days
            write-host $($app.displayname) secret expires in less than 30 days
            write-host $($secretCheck.EndDateTime)
        }
        elseif (($secretCheck.EndDateTime -le $date60) -and ($secretCheck.EndDateTime -ge $dateNow)) {
            $notice += $app | select @{Name='Name'; Expression = {$_.displayname}}
            $notice2 += $secretCheck | select @{Name='Expiration'; Expression = {$_.EndDateTime}}
            $timeremaining += $secretCheck.EndDateTime - $datenow | select days
            write-host $($app.displayname) secret expires in less than 60 days
            write-host $($secretCheck.EndDateTime)
        }
        elseif ($secretCheck.EndDateTime -le $dateNow) {
            $notice += $app | select @{Name='Name'; Expression = {$_.displayname}}
            $notice2 += $secretCheck | select @{Name='Expiration'; Expression = {$_.EndDateTime}}
            $timeremaining += $secretCheck.EndDateTime - $datenow | select days
            write-host $($app.displayname) SECRET IS EXPIRED
            write-host $($secretCheck.EndDateTime)
        }
    }
}

[int]$max = $notice.Count
if ([int]$notice2.count -gt [int]$notice.count) { $max = $notice2.Count; }
 
$Results = for ( $i = 0; $i -lt $max; $i++)
{
    [PSCustomObject]@{
        AppName = $notice.name[$i]
        Expiration = $notice2.Expiration[$i]
        DaysLeft = $timeremaining.days[$i]
 
    }
}

#Table Style
$style = "<style>BODY{font-family: Arial; font-size: 10pt;}"
$style = $style + "TABLE{border: 1px solid black; border-collapse: collapse;}"
$style = $style + "TH{border: 1px solid black; background: #dddddd; padding: 5px; }"
$style = $style + "TD{border: 1px solid black; background: #E8B3B3; padding: 5px; }"
$style = $style + "</style>"

$html = $results | ConvertTo-HTML -Title "App Secret Expirations" -PreContent "<h1>Upcoming App Secret Expirations</h1>" -Head $style

# Setup email parameters
$date = get-date -Format "MM-dd-yyyy"
$subject = "App Secret Expirations Report - $date"
$priority = "Normal"
$Body = ConvertTo-HTML -body "$html"
$emailTo = $mailsend
 
if ($html) {
    # Send the report email
    Send-MailMessage -To $emailTo -Subject $subject -BodyAsHtml ($body | Out-String) -SmtpServer $smtpServer -From $emailFrom -Priority $priority 
}