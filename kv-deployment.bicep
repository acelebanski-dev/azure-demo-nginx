@description('Specifies the Azure Active Directory tenant ID that should be used for authenticating requests to the key vault. Get it by using Get-AzSubscription cmdlet.')
param tenantId string = subscription().tenantId

@description('Specifies the object ID of a user, service principal or security group in the Azure Active Directory tenant for the vault. The object ID must be unique for the list of access policies. Get it by using Get-AzADUser or Get-AzADServicePrincipal cmdlets.')
param objectId string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Prefix for resource names.')
param namePrefix string = 'demo'

@description('Specifies the value of the secret that you want to create.')
@secure()
param secretValue string

var kvName = '${toLower(namePrefix)}-kv1'
var secretName = 'localAdmin'

resource kv 'Microsoft.KeyVault/vaults@2022-11-01' = {
  name: kvName
  location: location
  properties: {
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    tenantId: tenantId
    accessPolicies: [
      {
        objectId: objectId
        tenantId: tenantId
        permissions: {
          keys: [
            'all'
          ]
          secrets: [
            'all'
          ]
        }
      }
    ]
    sku: {
      name: 'standard'
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2022-11-01' = {
  parent: kv
  name: secretName
  properties: {
    value: secretValue
  }
}

output kvName string = kv.name
output kvResourceGroupName string = resourceGroup().name
output secretName string = secret.name
