//populate with GitHub login and repository name
$githubOrganizationName = 'philguth'
$githubRepositoryName = 'ALZNewGithub'

//Create Azure Active Directory Workload Identity (Application Registration)
//This command will output the AppId property that is your ClientId. The Id property is APPLICATION-OBJECT-ID and it will be used for creating federated credentials with Graph API calls.
$ApplicationRegistration = New-AzADApplication -DisplayName 'Canary'
//echo $ApplicationRegistration.AppId

//Associate Workload Identity with your Github repository
New-AzADAppFederatedCredential `
    -Name 'Canary' `
    -ApplicationObjectId $ApplicationRegistration.Id `
    -Issuer 'https://token.actions.githubusercontent.com' `
    -Audience 'api://AzureADTokenExchange' `
    -Subject "repo:$($githubOrganizationName)/$($githubRepositoryName):ref:refs/heads/main"

//Create a service principal for the Workload Identity (Application Registration)
$clientId = (Get-AzADApplication -DisplayName Canary).AppId
New-AzADServicePrincipal -ApplicationId $clientId

//Create a new role assignment for the service principal and assign to subscription
$objectId = (Get-AzADServicePrincipal -DisplayName Canary).Id
New-AzRoleAssignment -ObjectId $objectId -RoleDefinitionName Contributor //subscription level Contributor  

//Prepare Github Actions secrets
$azureContext = Get-AzContext
Write-Host "AZURE_CLIENT_ID: $($applicationRegistration.AppId)"
Write-Host "AZURE_TENANT_ID: $($azureContext.Tenant.Id)"
Write-Host "AZURE_SUBSCRIPTION_ID: $($azureContext.Subscription.Id)"