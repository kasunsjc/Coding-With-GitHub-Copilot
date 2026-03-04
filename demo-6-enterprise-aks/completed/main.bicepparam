using 'main.bicep'

param environmentName = 'dev'
param projectName = 'contoso'
param kubernetesVersion = '1.30'
param aksNodeCount = 3
param aksNodeVmSize = 'Standard_D4s_v5'
param jumpBoxAdminUsername = 'azureadmin'
