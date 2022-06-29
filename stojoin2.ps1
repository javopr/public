# Change the execution policy to unblock importing AzFilesHybrid.psm1 module
  Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser

# Define parameters
# $StorageAccountName is the name of an existing storage account that you want to join to AD
# $SamAccountName is the name of the to-be-created AD object, which is used by AD as the logon name for the object. See https://docs.microsoft.com/en-us/windows/win32/adschema/a-samaccountname
# for more information.
  $TenantId = "29b7d677-91c4-4717-abb3-224400c8bf44"
  $SubscriptionId = "655dabc5-b64e-475c-a455-28f571ea6186"
  $ResourceGroupName = "AVD-Infra"
  $StorageAccountName = "stojmoavdaeul01"
  $SamAccountName = "stojmoavdaeul01"
  $DomainAccountType = "ComputerAccount" # Default is set as ComputerAccount
  
# If you don't provide the OU name as an input parameter, the AD identity that represents the storage account is created under the root directory.
  $OuDistinguishedName = "OU=WVD,OU=Intechxsp,DC=intechxsp,DC=local"
# Specify the encryption algorithm used for Kerberos authentication. Using AES256 is recommended.
  $EncryptionType = "AES256"

# Navigate to where AzFilesHybrid is unzipped and stored and run to copy the files into your path
.\CopyToPSPath.ps1 

# Import AzFilesHybrid module
Import-Module -Name AzFilesHybrid

# Login with an Azure AD credential that has either storage account owner or contributor Azure role assignment
# If you are logging into an Azure environment other than Public (ex. AzureUSGovernment) you will need to specify that.
# See https://docs.microsoft.com/azure/azure-government/documentation-government-get-started-connect-with-ps
# for more information.
Connect-AzAccount -Tenant $TenantId -Subscription $SubscriptionId

# Select the target subscription for the current session
Select-AzSubscription -SubscriptionId $SubscriptionId 

# Register the target storage account with your active directory environment under the target OU (for example: specify the OU with Name as "UserAccounts" or DistinguishedName as "OU=UserAccounts,DC=CONTOSO,DC=COM"). 
# You can use to this PowerShell cmdlet: Get-ADOrganizationalUnit to find the Name and DistinguishedName of your target OU. If you are using the OU Name, specify it with -OrganizationalUnitName as shown below. If you are using the OU DistinguishedName, you can set it with -OrganizationalUnitDistinguishedName. You can choose to provide one of the two names to specify the target OU.
# You can choose to create the identity that represents the storage account as either a Service Logon Account or Computer Account (default parameter value), depends on the AD permission you have and preference. 
# Run Get-Help Join-AzStorageAccountForAuth for more details on this cmdlet.

Join-AzStorageAccount `
        -ResourceGroupName $ResourceGroupName `
        -StorageAccountName $StorageAccountName `
        -SamAccountName $SamAccountName `
        -DomainAccountType $DomainAccountType `
        -OrganizationalUnitDistinguishedName $OuDistinguishedName `
        -EncryptionType $EncryptionType

#Run the command below to enable AES256 encryption. If you plan to use RC4, you can skip this step.
Update-AzStorageAccountAuthForAES256 -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName

#You can run the Debug-AzStorageAccountAuth cmdlet to conduct a set of basic checks on your AD configuration with the logged on AD user. This cmdlet is supported on AzFilesHybrid v0.1.2+ version. For more details on the checks performed in this cmdlet, see Azure Files Windows troubleshooting guide.
Debug-AzStorageAccountAuth -StorageAccountName $StorageAccountName -ResourceGroupName $ResourceGroupName -Verbose
