#Param -- Default is AZOps
$ADServicePrincipal = "Canary"

#verify if AzureAD module is installed and running a minimum version, if not install with the latest version.
if (-not (Get-InstalledModule -Name "AzureAD" -MinimumVersion 2.0.2.130 ` -ErrorAction 'SilentlyContinue')) {

    Write-Host "AzureAD Module does not exist" -ForegroundColor 'Yellow'
    Install-Module -Name 'AzureAD' -Force
}
else {
    Write-Host "AzureAD Module exists with minimum version" -ForegroundColor 'Yellow'
}
Connect-AzureAD #sign in to Azure from Powershell, this will redirect you to a webbrowser for authentication, if required

#Verify Service Principal and if not pick a new one.
if (-not (Get-AzureADServicePrincipal -Filter "DisplayName eq '$ADServicePrincipal'")) { 
    Write-Host "ServicePrincipal doesn't exist or is not AZOps" -ForegroundColor 'Red'
    break
}
else { 
    Write-Host "$ADServicePrincipal exist" -ForegroundColor 'Green'
    $ServicePrincipal = Get-AzureADServicePrincipal -Filter "DisplayName eq '$ADServicePrincipal'"
    #Get Microsoft Entra Directory Role
    $DirectoryRole = Get-AzureADDirectoryRole -Filter "DisplayName eq 'Directory Readers'"
    #Add service principal to Directory Role
    Add-AzureADDirectoryRoleMember -ObjectId $DirectoryRole.ObjectId -RefObjectId $ServicePrincipal.ObjectId
}