// ============================================================
// Module: Jump Box VM
// Enterprise Private AKS - Management VM for kubectl Access
// ============================================================

@description('Azure region for all resources')
param location string

@description('Project name used for resource naming')
param projectName string

@description('Environment name')
@allowed(['dev', 'staging', 'prod'])
param environmentName string

@description('Resource tags')
param tags object

@description('Jump box subnet resource ID')
param jumpboxSubnetId string

@description('Admin username for the jump box VM')
param adminUsername string

@description('Admin password for the jump box VM')
@secure()
param adminPassword string

@description('VM size for the jump box')
param vmSize string = 'Standard_B2ms'

// === VARIABLES ===
var vmName = 'vm-${projectName}-jumpbox-${environmentName}'
var nicName = 'nic-${vmName}'
var osDiskName = 'osdisk-${vmName}'

// Cloud-init script to install kubectl, helm, and Azure CLI
var cloudInitScript = '''
#cloud-config
package_update: true
package_upgrade: true
packages:
  - apt-transport-https
  - ca-certificates
  - curl
  - gnupg
  - lsb-release

runcmd:
  # Install Azure CLI
  - curl -sL https://aka.ms/InstallAzureCLIDeb | bash

  # Install kubectl
  - curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  - echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
  - apt-get update
  - apt-get install -y kubectl

  # Install Helm
  - curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

  # Install kubelogin for Azure AD authentication
  - az aks install-cli

  # Create kubectl alias for all users
  - echo 'alias k=kubectl' >> /etc/bash.bashrc
  - echo 'complete -F __start_kubectl k' >> /etc/bash.bashrc
'''

// === NETWORK INTERFACE ===

@description('Network interface for jump box VM')
resource nic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: nicName
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: jumpboxSubnetId
          }
        }
      }
    ]
  }
}

// === VIRTUAL MACHINE ===

@description('Jump box VM for AKS management')
resource vm 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: vmName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned' // Managed identity for Azure authentication
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        name: osDiskName
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        deleteOption: 'Delete'
      }
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
        provisionVMAgent: true
        patchSettings: {
          patchMode: 'AutomaticByPlatform'
          automaticByPlatformSettings: {
            rebootSetting: 'IfRequired'
          }
        }
      }
      customData: base64(cloudInitScript)
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

// === VM EXTENSION: AZURE MONITOR AGENT ===

@description('Azure Monitor Agent extension for VM monitoring')
resource amaExtension 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = {
  parent: vm
  name: 'AzureMonitorLinuxAgent'
  location: location
  tags: tags
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorLinuxAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
  }
}

// === OUTPUTS ===

@description('Jump box VM resource ID')
output vmId string = vm.id

@description('Jump box VM name')
output vmName string = vm.name

@description('Jump box VM managed identity principal ID')
output vmPrincipalId string = vm.identity.principalId

@description('Jump box VM private IP address')
output vmPrivateIp string = nic.properties.ipConfigurations[0].properties.privateIPAddress
