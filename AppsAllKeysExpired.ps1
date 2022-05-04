#Authentication using the system assigned managed identity for this Automation Account
Connect-Azaccount -Identity


# Create column headers of Table1
$HtmlTable1 = "<table border='1' align='Left' cellpadding='2' cellspacing='0' style='color:black;font-family:arial,helvetica,sans-serif;text-align:left;'>
<tr style ='font-size:13px;font-weight: normal;background: #FFFFFF'>
<th align=left><b>Application Id</b></th>
<th align=left><b>Display Name</b></th>
</tr>"

$actualDate = Get-Date
$apps = Get-AzADApplication
foreach ($app in $apps)
{
    [bool] $isNotExpired = $false
    [bool] $isOldExpired = $false
    $appCreds = Get-AzADAppCredential -ApplicationId $app.AppId
    
    if ($null -ne $appCreds)
    {
        foreach ($appCred in $appCreds)
        {
            $diffDate = New-TimeSpan -Start $actualDate -End $appCred.EndDateTime
            #Verifico si las credenciales aun no expiraron
            if ($diffDate.Days -gt 0)
            {
                $isNotExpired = $true                
            }   
            #Verifico si las credenciales expiraron hace mas de 6 meses         
            if ($diffDate.Days -le -180)
            {
                $isOldExpired = $true                                
            }                                              
        }
        if (!$isNotExpired -and $isOldExpired) 
        {
            $HtmlTable1 += "<tr style='font-size:13px;background-color:#FFFFFF'>
            <td>" + $app.ApplicationId + "</td>
            <td>" + $app.DisplayName + "</td>                
            </tr>"            
        }   
    }        
}    

$HtmlTable1 += "</table>"

$OfficeCred = Get-AutomationPSCredential -Name "<O365CredentialName>"
Send-MailMessage -Credential $OfficeCred -SmtpServer smtp.office365.com -Port 587 `
-To "<TO email address>" `
-Subject "Apps with more than 6 months expired" `
-Body $HtmlTable1 `
-From $OfficeCred.UserName `
-BodyAsHtml `
-UseSsl
