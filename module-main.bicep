@description('Existing KeyVault name passed to template.')
param kvName string

@description('Existing KeyVault Resource Group passed to template')
param kvResourceGroupName string

@description('Existing KeyVault Resource Group passed to template')
param secretName string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Prefix for resource names.')
param namePrefix string = 'demo'

@description('Trusted public IP address to access the Application Gateway (use CIDR notation).')
@minLength(9)
@maxLength(18)
param allowedIp string

@description('Size of VMs in the VM Scale Set.')
@allowed([
  'Standard_B2s'
  'Standard_B2ms'
  'Standard_D2_v3'
])
param vmSku string = 'Standard_B2s'

@description('Number of VM instances in the VM Scale Set (100 or less).')
@minValue(1)
@maxValue(6)
param instanceCount int = 2

@description('Admin username on all VMs.')
param adminUsername string = 'ac-admin'

resource kv 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: kvName
  scope: resourceGroup(kvResourceGroupName)
}

module nginxhello 'module-nginxhello.bicep' = {
  name: 'nginxhello'
  params: {
    location: location
    namePrefix: namePrefix
    allowedIp: allowedIp
    vmSku: vmSku
    instanceCount: instanceCount
    adminUsername: adminUsername
    adminPassword: kv.getSecret(secretName)
  }
}
