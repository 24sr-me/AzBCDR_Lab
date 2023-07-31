# Azure BCDR Lab

This repo contains the required bicep files to deploy a full lab environment for backup and disaster recovery testing/demo.

The following resources will be deployed:

- Two Resource Groups. One in the production region and one in the recovery region.
- Separate VNETs for production, recovery and test.
- Two Virtual Machines in production running webapp.
- Recovery Services Vault in production region used for backup of Virtual Machines.
- Recovery Services Vault in second region used for Azure Site Recovery replication of Virtual Machines.
- Traffic Manager for automatic failover of users between production and DR
- Public IP addresses to be used for Virtual Machines in both production, DR and testing.
- Network Security Groups in both production and DR, attched to subnets.
- assignment of built in policy "Configure disaster recovery on virtual machines by enabling replication via Azure Site Recovery".

## Deployment

### Powershell

- Log in to Azure using ```Connect-AzAccount```
- Set the taregt subscription using ```Set-AzSubscription```
- Deploy from template with ```New-AzSubscriptionDeployment -TemplateFile main.bicep```
- Input target region for production
- Input password for Virtual Machines

### Azure CLI

- Log in to Azure using ```az login```
- Set the taregt subscription using ```az account set```
- Deploy from template with ```az deployment sub create --location <prod_location> --template-file .\main.bicep```
- Input password for Virtual Machines

## Configuration

Post deployment further configuration is required for a smoother demonstration of seamless failover. On each VM the following settings should be changed:

- From **Azure Portal**, go to **Virtual Machine**
- Under **Operations** select **Disaster Recovery**
- Under **General** select **Network**
- From top menu select **Edit**
- Change **"Test failover network"** to the testing VNET
- Under **General Settings > Test failover** settings set subnet to default
- Under **Primary IP Configuration** set test failover settings and failover settings set Public IP to pip-dr-vm-\<nameID>-1
- From top menu select **Save**
- Repeat for second VM

# Disaster Recovery Demo Guide
## Prep
Prior to testing collect the following information from the deployment:
- From rg-\<nameID>
  - traf-\<namdID> collect DNS name
  - vm-\<namdID>-1 and vm-\<namdID>-1 collect Public IP address
- From rg-\<nameID>-asr
  - pip-dr-\<namdID>-1 amd pip-dr-\<namdID>-2

## Pre-Failover Test
Open a web browser and connect on port 80 to the DNS name of the traffic manager and both VM public IPs. VMs should display their own name and the region they are running from. Traffic Manager should rotate between both servers

## Test Failover
In the Azure Portal browse to a **demo VM > Operations > Disaster Recovery**. Along the top menu bar select **Test Failover**. Use teh default settings for test.
Monitor the from portal. Once failover is complete connect to the relevant pubic IP address of the failed over server from a web browser on port 80. Server nam should be dispalyed with the recovery region.
In Azure portal select Clean Up Failover

## Live Failover
In the Azure Portal browse to a **demo VM > Operations > Disaster Recovery**. Along the top menu bar select Failover. Check that you understand the risk and continue. Check to shutdown machine before failing over/
Monitor from portal. Once failover is complete connect to Traffic Manager to show that user connection path remains the same. If only one server is failed over interface should rotate between regions.

## Clean-up

To remove the demo environment backup and repliaction first need disabling:

- Remove backup
  - Browse to production RSV
  - Under select **Protected Items > Backup Items > Azure Virtual Machines**
  - For each VM select the elipsis (...) > **Stop Backup**
  - Select Delete backup data, enter server name and give a reason
- Remove replication
  - Browse to recovery RSV
  - Under select **Protected Items > Replicated Items**
  - For each VM select the elipsis (...) > **Disable Replication**
- Delete both resource groups

# Details

## Paramaters

**prodlocation** - defined region for production side of environment. Defaults set to 'uksouth' but due to bicep limitation location still required to be set at run time.

**drlocation** - region to be used for recovery. DR and testing resources to be deployed here. Default region UK West.

**namdID** - sets unique value for resource naming. Defaults to current date/time using yyMMddHHmm format.

**rgname** - resource group name for production resources. Defaults to rg-\<yyMMddHHmm>

**rgnameasr** - resource group name for DR and testing resources. Defaults to rg-\<yyMMddHHmm>-asr

**adminUsername** - operaring system admin password for deployed VMs. Defaults to 'BCDR'

**adminPassword** - Password for adminUsername account. Required, prompted for if not set.

**policyDefinitionID** - Azure Policy ID of builtin policy for ASR configuration on VMs. Default setting '/providers/Microsoft.Authorization/policyDefinitions/ac34a73f-9fa5-4067-9247-a3ecae514468'

## Naming

All resource names are based off the nameID paramater. The default value is teh current date/time in yyMMddHHmm. The format of all names is:

\<type>-\<nameID>-\<suffix>

Type denotes the resource type using [Microsoft provided abbriviations](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations).

## Resource Groups

Resource Groups are created in the defined production and DR locations. These are created using the names defined by the paramaters, if not set they will be named rg-\<yyMMddHHmm> and rg-\<yyMMddHHmm>-asr

## Virtual Networks

Three virtual networks are created, one in production and two in DR with the following setting:

- | Production | Disaster Recovery | Testing
--- | --- | --- | ---
Name | vnet-\<nameID>-prod | vnet-\<nameID>-dr | vnet-\<nameID>-test
Subet | default | default | default
Location | producton | DR | DR
Address Prefix | 10.1.0.0/24 | 10.2.0.0/24 | 10.3.0.0/24
Remote Peer | vnet-\<nameID>-dr | vnet-\<nameID>-prod | none

Each VNET template also deploys a Network Security Group with a rule to allow port 80 inbound.
## Recovery Service Vaults

Two Recovery Service Vaults are deployed. One in production used for backup of virtual machines and one in the DR location used by Azure Site Recovery for replication of VMs.

**NB** To enable easier clean-up soft delete settings are disabled on both Recovery Service Vaults. This means that they should never be used for production.

## Azure Policy

The built in Policy "Configure disaster recovery on virtual machines by enabling replication via Azure Site Recovery" is assigned on the production resource group and configured to enable replication for both deployed VMs to the second region.

To facilitate remediation a system managed idenity is created and assigned owner to the two created resource groups.

## Public IPs

Four public IPs are created, one for each VM in each location. Production public IPs are created with the virtual machines. DR public IPs are created seprately so they are pre-created for failover.

## Virtual Machines

Two VMs are deployed to the production region. Each VM contains a web page which displays its server name and the region it is currently running, this can be used to demonstrate failover.

Private IP address are dynamic. Public IPs are created as part of the VM template.

As VMs are created they are added to backup to the production region RSV. 

## Traffic Manager

Traffic Manager is used to load balance between VMs running. The deployed Traffic Manager Profile is configured to direct traffic to the public IPs in production and recovery regions. A client device can be used to connect to the Traffic Manager DNS name and will connect to the Virtual Machines wherever they are running,