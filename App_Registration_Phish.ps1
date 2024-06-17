Import-Module AzureAD

Import-Module Az

Write-Host "Please log in to your Azure account..."

Connect-AzureAD

Connect-AzAccount

$redirectUri = Read-Host "Please enter the Redirect URI"

  

# Add App Name here

$appName = "SuperSecureAppRegistration"

# Modify Tenant Domain Below

$app = New-AzureADApplication -DisplayName $appName -IdentifierUris "https://$($appName).<TENANT_DOMAIN>.com" -ReplyUrls $redirectUri

$appId = $app.AppId

  

Write-Host "Azure AD App registration created successfully with AppId: $appId"

  

# Creates a new client secret that you'll get the value of, eventually

$secret = New-AzureADApplicationPasswordCredential -ObjectId $app.ObjectId -CustomKeyIdentifier "MySecret" -StartDate (Get-Date) -EndDate (Get-Date).AddYears(1)

Write-Host "Client Secret created successfully."

Write-Host "Client Secret: $($secret.Value)"

  

# Added Read Only permissions that (probably) won't require admin access

$graphServicePrincipal = Get-AzureADServicePrincipal -Filter "displayName eq 'Microsoft Graph'"

$apiPermission = New-Object -TypeName Microsoft.Open.AzureAD.Model.RequiredResourceAccess

$apiPermission.ResourceAppId = $graphServicePrincipal.AppId

$readOnlyPermissionGUIDs = @(
    [Guid]::Parse("e1fe6dd8-ba31-4d61-89e7-88639da4683d"), # User.Read
    [Guid]::Parse("df021288-bdef-4463-88db-98f22de89214"), # User.Read.All
    [Guid]::Parse("5b567255-7703-4780-807c-7be8301ae99b"), # Group.Read.All
    [Guid]::Parse("f123b6f0-41d5-4bf2-9a45-d7b52e7fbe62"), # Offline Access
    [Guid]::Parse("c4e0efe7-fd0b-43c5-8f79-3fd5468ad321"), # User.ReadBasic.All
    [Guid]::Parse("5f8c59db-677d-491f-a6b8-5f174b11ec1d"), # Calendars.Read
    [Guid]::Parse("ff5c56b3-b6f1-4e1b-98ab-1cb0cc59e2f1"), # Contacts.Read
    [Guid]::Parse("570282fd-fa5c-430d-a7fd-fc8dc98a9dca"), # Mail.Read
    [Guid]::Parse("df85f4d6-2057-4f62-9be4-dc75d252e397"), # Notes.Read.All
    [Guid]::Parse("df85f4d6-2057-4f62-9be4-dc75d252e397"), # Files.Read.All
    [Guid]::Parse("570282fd-fa5c-430d-a7fd-fc8dc98a9dca"), # Sites.Read.All
    [Guid]::Parse("5b567255-7703-4780-807c-7be8301ae99b"), # Group.Read.All
    [Guid]::Parse("57789990-1257-4242-b9dd-7d3e0c1073a7"), # Directory.Read.All
    [Guid]::Parse("14dd3dd5-dc3f-4a6d-bc1c-a28cf4dd0c1e"), # Reports.Read.All
    [Guid]::Parse("2020aa4a-fd35-4195-9194-bba411f1c3f6"), # Tasks.Read
    [Guid]::Parse("af376a6b-d4d9-43b2-9077-3272d8d1eb33")  # People.Read
)


$resourceAccessArray = @()
foreach ($permissionGUID in $readOnlyPermissionGUIDs) {
    $resourceAccess = New-Object -TypeName Microsoft.Open.AzureAD.Model.ResourceAccess
    $resourceAccess.Id = $permissionGUID
    $resourceAccess.Type = "Scope"
    $resourceAccessArray += $resourceAccess
}


$apiPermission = New-Object -TypeName Microsoft.Open.AzureAD.Model.RequiredResourceAccess
$apiPermission.ResourceAppId = $graphServicePrincipalAppId
$apiPermission.ResourceAccess = $resourceAccessArray


Set-AzureADApplication -ObjectId $app.ObjectId -RequiredResourceAccess @($apiPermission)
Write-Host "API permissions added successfully."


Write-Host "AppId: $appId"

Write-Host "Redirect URI: $redirectUri"

Write-Host "Client Secret: $($secret.Value)"

# Modify Tenant ID here to generate clickable, ready to go links

Write-Host "`nTo complete the OAuth2 authorization flow, use the following URL:"

Write-Host "https://login.microsoftonline.com/<TENANT_IDENTIFIER>/oauth2/v2.0/authorize?client_id=$appId&response_type=code&redirect_uri=$redirectUri&response_mode=query&scope=email%20mail.read%20offline_access%20openid%20people.read%20profile%20user.read&state=12345"

Write-Host "`nAfter the user consents, they will be redirected to the provided redirect URI with an authorization code."

Write-Host "Exchange the authorization code for tokens using a POST request to:"

Write-Host "https://login.microsoftonline.com/<TENANT_IDENTIFIER>/oauth2/v2.0/token"

Write-Host "Include the following parameters in the body of the POST request:"

Write-Host "`nclient_id=$appId"

Write-Host "client_secret=$($secret.Value)"

Write-Host "grant_type=authorization_code"

Write-Host "code=<Authorization Code from Redirect URI>"

Write-Host "redirect_uri=$redirectUri"