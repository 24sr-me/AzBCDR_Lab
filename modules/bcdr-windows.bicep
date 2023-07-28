/*
  create a single standalone VM with own virtual network. No public IP
  Defult username stu
  Password to be passed via paramater

  current date used in all names for uniqueness in ddMMyyhhmm format  
*/

@description('Username for the Virtual Machine.')
param adminUsername string

@description('Password for the Virtual Machine.')
@minLength(12)
@secure()
param adminPassword string

@description('Name of the virtual machine.')
param vmName string

@description('The Windows version for the VM. This will pick a fully patched image of this given Windows version.')
param OSVersion string = '2022-datacenter-azure-edition'

@description('Size of the virtual machine.')
param vmSize string = 'Standard_B2ms'

@description('Location for all resources.')
param location string = resourceGroup().location

param subnetName string = 'default'
param virtualNetworkName string

var nicName = '${vmName}_nic'
var publicIpName = 'pip-${vmName}'

param vaultName string
param rsvid string
param ip string

var backupFabric = 'Azure'
var backupPolicyName = 'DefaultPolicy'
var protectionContainer = 'iaasvmcontainer;iaasvmcontainerv2;${resourceGroup().name};${vmName}'
var protectedItem = 'vm;iaasvmcontainerv2;${resourceGroup().name};${vmName}'



resource publicIp 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: { 
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: vmName
    }
  }
}



resource nic 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          privateIPAddress: ip
          publicIPAddress: {
            id: publicIp.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
          }
        }

      }
    ]
  }

}

resource vm 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: OSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
        }
    }
  }

}

resource vaultName_backupFabric_protectionContainer_protectedItem 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2020-02-02' = {
  name: '${vaultName}/${backupFabric}/${protectionContainer}/${protectedItem}'
  properties: {
    protectedItemType: 'Microsoft.Compute/virtualMachines'
    policyId: '${rsvid}/backupPolicies/${backupPolicyName}'
    sourceResourceId: vm.id
  }
}

resource vmFEIISEnabled 'Microsoft.Compute/virtualMachines/runCommands@2022-03-01' = {
  name: 'vm-EnableIIS-Script-${vmName}'
  location: location
  parent: vm
  properties: {
    asyncExecution: false
    source: {
      script: '''
$htmlscript = @'

$info = Invoke-RestMethod -Headers @{"Metadata"="true"} -Method GET -Uri "http://169.254.169.254/metadata/instance?api-version=2021-02-01"
$html = @"
<!DOCTYPE html>
<html>
<head>
    <style>
      body {
          background-color: rgb(0, 127, 255);
      }
    </style>
    <h1 style="font-size:6em; "> Web App </h1>
    <h2 style="font-size:6em; "> $("Server: " + $env:computername) </h2>
    <h2 style="font-size:6em; "> $("Location: " + $info.compute.location) </h2>


</head>
<body>
</body>
</html>
"@

set-Content -Path "C:\inetpub\wwwroot\iisstart.htm" -Value $html  

'@
      New-Item -Path 'c:\asrDemo\' -ItemType Directory
      Install-WindowsFeature -name Web-Server -IncludeManagementTools
      set-Content -Path "c:\asrDemo\WebApp.ps1" -Value $htmlscript
      schtasks /create /tn "Update Web App" /sc onstart /delay 0000:30 /rl highest /ru system /tr "powershell.exe -file c:\asrDemo\WebApp.ps1"
      schtasks /Run /TN "Update Web App"
      '''
    }
  }
}

output outpublicIP string = publicIp.properties.ipAddress
output outID string = publicIp.id
