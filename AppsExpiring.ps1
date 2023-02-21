
#Uncomment one of these two methods for Azure Authentication:

#For Automation Accounts with System Assigned Managed Identity
#Connect-AzAccount -Identity

#For Automation Accounts with credentials configured as connection
#$Conn = Get-AutomationConnection -Name '<ConnectionName>'



# Create column headers of Table1
$HtmlTable1 = "<table border='1' align='Left' cellpadding='2' cellspacing='0' style='color:black;font-family:arial,helvetica,sans-serif;text-align:left;'>
<tr style ='font-size:13px;font-weight: normal;background: #FFFFFF'>
<th align=left><b>Application Id</b></th>
<th align=left><b>Display Name</b></th>
<th align=left><b>Days until expiration</b></th>
<th align=left><b>Type</b></th>
<th align=left><b>Expiration date</b></th>
</tr>"


$actualDate = Get-Date
$apps = Get-AzADApplication
$appscounter = 0
foreach ($app in $apps)
{
    $appCreds = Get-AzADAppCredential -ObjectId $app.ObjectId
    if ($null -ne $appCreds)
    {
        foreach ($appCred in $appCreds)
        {
            #Here we do the time math and check for the 30 days or less. If wider or shorter time frame is needed, just change the 30 days to another day sum
            $diffDate = New-TimeSpan -Start $actualDate -End $appCred.EndDate
            if ($diffDate.Days -le 30)
            {
                #You found yourself a culprit, lets wrap it up and send it to the black list :)
                $HtmlTable1 += "<tr style='font-size:13px;background-color:#FFFFFF'>
                <td>" + $app.ApplicationId + "</td>
                <td>" + $app.DisplayName + "</td>
                <td>" + $diffDate.Days + "</td>
                <td>" + $appCred.Type + "</td>
                <td>" + $appCred.EndDate + "</td>
                </tr>" 
                $appscounter ++               
            }             
        }        
    }    
}
$HtmlTable1 += "</table>"



#Credentials for sending email with user password stored as secret in Key Vault.
$AccountServices = (Get-AzKeyVaultSecret -VaultName '<VaultName>' -Name '<SecretName>').SecretValue
$ASUserDomain = "<username@domain.com>"
$credObject = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ASUserDomain, $AccountServices

#Another alternative to store/retrieve credentials in the Automation Account.  
#$credObject = Get-AutomationPSCredential -Name "<CredentialName>"

$emailTo = @('user1@domain.com', 'user2@domain.com', 'user3@domain.com')
if ($appscounter -gt 0)
 {
    Send-MailMessage -Credential $credObject -SmtpServer smtp.office365.com -Port 587 `
    -To $emailTo `
    -Subject "<Some Descriptive subject as String>" `
    -Body $HtmlTable1 `
    -From '$ASUserDomain or $credObect.UserName' `
    -BodyAsHtml `
    -UseSsl
 }
