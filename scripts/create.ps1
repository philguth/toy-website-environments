//populate with GitHub login and repository name
$githubOrganizationName = 'philguth'
$githubRepositoryName = 'ALZNewGithub'

//Create Azure Active Directory Workload Identity (Application Registration)
//This command will output the AppId property that is your ClientId. The Id property is APPLICATION-OBJECT-ID and it will be used for creating federated credentials with Graph API calls.
$ApplicationRegistration = New-AzADApplication -DisplayName 'Canary'
//echo $ApplicationRegistration.AppId

//Associate Workload Identity with your Github repository
New-AzADAppFederatedCredential `
   -Name 'ALZNewGithub' `
   -ApplicationObjectId $ApplicationRegistration.Id `
   -Issuer 'https://token.actions.githubusercontent.com' `
   -Audience 'api://AzureADTokenExchange' `
   -Subject "repo:$($githubOrganizationName)/$($githubRepositoryName):ref:refs/heads/main"

//Create a service principal for the Workload Identity (Application Registration)
$clientId = (Get-AzADApplication -DisplayName Canary).AppId
New-AzADServicePrincipal -ApplicationId $clientId

//Create a new role assignment for the service principal and assign to resource group (or subscription)
$objectId = (Get-AzADServicePrincipal -DisplayName Canary).Id
New-AzRoleAssignment -ObjectId $objectId -RoleDefinitionName Contributor -ResourceGroupName $resourceGroupName
New-AzRoleAssignment -ObjectId $objectId -RoleDefinitionName Contributor //subscription level Contributor  


New-AzADAppFederatedCredential `
   -Name 'ALZNewGithub' `
   -ApplicationObjectId $testApplicationRegistration.Id `
   -Issuer 'https://token.actions.githubusercontent.com' `
   -Audience 'api://AzureADTokenExchange' `
   -Subject "repo:$($githubOrganizationName)/$($githubRepositoryName):environment:canary"
New-AzADAppFederatedCredential `
   -Name 'ALZNewGithubBranch' `
   -ApplicationObjectId $ApplicationRegistration.Id `
   -Issuer 'https://token.actions.githubusercontent.com' `
   -Audience 'api://AzureADTokenExchange' `
   -Subject "repo:$($githubOrganizationName)/$($githubRepositoryName):ref:refs/heads/main"

$productionApplicationRegistration = New-AzADApplication -DisplayName 'toy-website-environments-production'
New-AzADAppFederatedCredential `
   -Name 'toy-website-environments-production' `
   -ApplicationObjectId $productionApplicationRegistration.Id `
   -Issuer 'https://token.actions.githubusercontent.com' `
   -Audience 'api://AzureADTokenExchange' `
   -Subject "repo:$($githubOrganizationName)/$($githubRepositoryName):environment:Production"
New-AzADAppFederatedCredential `
   -Name 'toy-website-environments-production-branch' `
   -ApplicationObjectId $productionApplicationRegistration.Id `
   -Issuer 'https://token.actions.githubusercontent.com' `
   -Audience 'api://AzureADTokenExchange' `
   -Subject "repo:$($githubOrganizationName)/$($githubRepositoryName):ref:refs/heads/main"



$testResourceGroup = New-AzResourceGroup -Name ToyWebsiteTest -Location northcentralus

New-AzADServicePrincipal -AppId $($testApplicationRegistration.AppId)
New-AzRoleAssignment `
   -ApplicationId $($testApplicationRegistration.AppId) `
   -RoleDefinitionName Contributor `
   -Scope $($testResourceGroup.ResourceId)


$productionResourceGroup = New-AzResourceGroup -Name ToyWebsiteProduction -Location northcentralus

New-AzADServicePrincipal -AppId $($productionApplicationRegistration.AppId)
New-AzRoleAssignment `
   -ApplicationId $($productionApplicationRegistration.AppId) `
   -RoleDefinitionName Contributor `
   -Scope $($productionResourceGroup.ResourceId)



$azureContext = Get-AzContext
Write-Host "AZURE_CLIENT_ID_TEST: $($ApplicationRegistration.AppId)"
Write-Host "AZURE_CLIENT_ID_PRODUCTION: $($productionApplicationRegistration.AppId)"
Write-Host "AZURE_TENANT_ID: $($azureContext.Tenant.Id)"
Write-Host "AZURE_SUBSCRIPTION_ID: $($azureContext.Subscription.Id)"



==============================================

https://github.com/Azure/Enterprise-Scale/wiki/ALZ-Setup-azure
#sign in to Azure from Powershell, this will redirect you to a webbrowser for authentication, if required
Connect-AzAccount

#get object Id of the current user (that is used above)
$user = Get-AzADUser -UserPrincipalName (Get-AzContext).Account

#assign Owner role at Tenant root scope ("/") as a User Access Administrator to current user
New-AzRoleAssignment -Scope '/' -RoleDefinitionName 'Owner' -ObjectId $user.Id

#(optional) assign Owner role at Tenant root scope ("/") as a User Access Administrator to service principal (set $spndisplayname to your service principal displayname)
$spndisplayname = "Canary"
$spn = (Get-AzADServicePrincipal -DisplayName $spndisplayname).id
New-AzRoleAssignment -Scope '/' -RoleDefinitionName 'Owner' -ObjectId $spn