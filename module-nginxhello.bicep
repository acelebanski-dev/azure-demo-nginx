@description('Location for all resources.')
param location string

@description('Prefix for resource names.')
param namePrefix string

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
param vmSku string

@description('Number of VM instances in the VM Scale Set (100 or less).')
@minValue(1)
@maxValue(6)
param instanceCount int

@description('Admin username on all VMs.')
param adminUsername string

@description('Admin password on all VMs.')
@secure()
param adminPassword string

var vnetName = '${toLower(namePrefix)}-vnet1'
var vnetPrefix = '10.10.0.0/16'
var subnets = [
  {
    name: 'ServerSubnet'
    subnetPrefix: '10.10.0.0/24'
  }
  {
    name: 'AppGwSubnet'
    subnetPrefix: '10.10.1.0/24'
  }
  {
    name: 'AzureBastionSubnet'
    subnetPrefix: '10.10.2.0/26'
  }
]
var publicIpName = '${toLower(namePrefix)}-pip'
var bastionName = '${toLower(namePrefix)}-bastion1'
var appGwName = '${toLower(namePrefix)}-appgw1'
var appGwWafName = '${appGwName}-waf'
var vmssName = '${toLower(namePrefix)}-vmss1'
var nicName = '${vmssName}-nic'
var ipConfigName = '${vmssName}-ipconfig'
var nsgName = '${nicName}-nsg'
var autoscaleSettingsName = '${vmssName}-autoscalesettings'

resource vnet 'Microsoft.Network/virtualNetworks@2022-09-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetPrefix
      ]
    }
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.subnetPrefix
      }

    }]
  }
}

resource pip 'Microsoft.Network/publicIPAddresses@2022-09-01' = [for i in range(1, 2): {
  name: '${publicIpName}${i}'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}]

resource bastion 'Microsoft.Network/bastionHosts@2022-09-01' = {
  name: bastionName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    scaleUnits: 2
    disableCopyPaste: false
    enableFileCopy: false
    enableIpConnect: false
    enableShareableLink: false
    enableTunneling: false
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pip[0].id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, 'AzureBastionSubnet')
          }
        }
      }
    ]
  }
}

resource waf 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2022-09-01' = {
  name: appGwWafName
  location: location
  properties: {
    customRules: [
      {
        name: 'BlockUnknownIP'
        priority: 5
        ruleType: 'MatchRule'
        action: 'Block'
        matchConditions: [
          {
            matchVariables: [
              {
                variableName: 'RemoteAddr'
              }
            ]
            operator: 'IPMatch'
            negationConditon: true
            matchValues: [
              allowedIp
            ]
          }
        ]
      }
    ]
    policySettings: {
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      fileUploadLimitInMb: 100
      state: 'Enabled'
      mode: 'Prevention'
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'OWASP'
          ruleSetVersion: '3.2'
          ruleGroupOverrides: []
        }
      ]
    }
  }
}

resource appgw 'Microsoft.Network/applicationGateways@2022-09-01' = {
  name: appGwName
  location: location
  zones: [
    '1'
    '3'
  ]
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
    }
    gatewayIPConfigurations: [
      {
        name: 'appGwIpConfig'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, 'AppGwSubnet')
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIp'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pip[1].id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'myBackendPool'
        properties: {}
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'myHTTPSetting'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          requestTimeout: 20
        }
      }
    ]
    httpListeners: [
      {
        name: 'ListenHTTP'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGwName, 'appGwPublicFrontendIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGwName, 'port_80')
          }
          protocol: 'Http'
          requireServerNameIndication: false
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'myRoutingRule'
        properties: {
          ruleType: 'Basic'
          priority: 100
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGwName, 'ListenHTTP')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGwName, 'myBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGwName, 'myHTTPSetting')
          }
        }
      }
    ]
    enableHttp2: false
    forceFirewallPolicyAssociation: true
    autoscaleConfiguration: {
      minCapacity: 1
      maxCapacity: 6
    }
    firewallPolicy: {
      id: waf.id
    }
  }
  dependsOn: [
    vnet
    pip[1]
  ]
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2022-09-01' = {
  name: nsgName
  location: location
}

resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2022-11-01' = {
  name: vmssName
  location: location
  sku: {
    name: vmSku
    tier: 'Standard'
    capacity: instanceCount
  }
  zones: [
    '1'
    '3'
  ]
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    overprovision: false
    upgradePolicy: {
      mode: 'Manual'
    }
    singlePlacementGroup: false
    platformFaultDomainCount: 1
    virtualMachineProfile: {
      storageProfile: {
        osDisk: {
          osType: 'Linux'
          caching: 'ReadWrite'
          createOption: 'FromImage'
        }
        imageReference: {
          publisher: 'canonical'
          offer: '0001-com-ubuntu-server-focal'
          sku: '20_04-lts-gen2'
          version: 'latest'
        }
      }
      osProfile: {
        computerNamePrefix: vmssName
        adminUsername: adminUsername
        adminPassword: adminPassword
        customData: base64(loadTextContent('cloud-init.txt'))
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: nicName
            properties: {
              primary: true
              networkSecurityGroup: {
                id: nsg.id
              }
              ipConfigurations: [
                {
                  name: ipConfigName
                  properties: {
                    subnet: {
                      id: vnet.properties.subnets[0].id
                    }
                    privateIPAddressVersion: 'IPv4'
                    applicationGatewayBackendAddressPools: [
                      {
                        id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGwName, 'myBackendPool')
                      }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }
    }
  }
  dependsOn: [
    appgw
  ]
}

resource autoscalesettings 'Microsoft.Insights/autoscalesettings@2022-10-01' = {
  name: autoscaleSettingsName
  location: location
  properties: {
    name: autoscaleSettingsName
    targetResourceUri: vmss.id
    enabled: true
    profiles: [
      {
        name: 'Profile1'
        capacity: {
          minimum: '2'
          maximum: '6'
          default: '2'
        }
        rules: [
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricResourceUri: vmss.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: 75
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricResourceUri: vmss.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: 25
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
        ]
      }
    ]
  }
}
