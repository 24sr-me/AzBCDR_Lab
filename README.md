# Azure BCDR Lab

This repo contains the required bicep files to deploy a full lab environment for backup and disaster recovery testing/demo.

The following resources will be deployed:

- One Resource Group for production and one for recovery
- separate VNETs for production, recovery and test
- two Virtual Machines in production running webapp
- Recovery Services Vault in production region used for backup of Virtual Machines
- Recovery Services Vault in second region used for Azure Site REcovery replication of Virtual Machines
- Traffic Manager for automatic failover of users between production and DR
- Public IP addresses to be used for Virtual Machines in both production, DR and testing
- Network Security Groups in both production and DR, attched to subnets
- assignment of built in policy "Configure disaster recovery on virtual machines by enabling replication via Azure Site Recovery"

## Deployment

### Powershell

Log in to Azure using ```Connect-AzAccount```
Set the taregt subscription using ```Set-AzSubscription```
Deploy from template with ```New-AzSubscriptionDeployment -TemplateFile main.bicep```
Input target region for production
Input password for Virtual Machines

### Azure CLI

Log in to Azure using ```az login```
Set the taregt subscription using ```az account set```
Deploy from template with ```az deployment sub create --location <prod_location> --template-file .\main.bicep```
Input password for Virtual Machines

## Configuration

Post deployment further configuration is required for a smoother demonstration of seamless failover. On each VM the following settings should be changed:

From Azure Portal, go to Virtual Machine
Under Ooperations select Disaster Recovery
Under General select Network
From top menu select Edit
Change "Test failover network" to the testing VNET
Under General Settings > Test failover settings set subnet to default
Under Primary IP Configuration Test failover settings and Failover settings set Public IP to pip-dr-vm-\<nameID>-1
From top menu select Save
Repeat for second VM

# Disaster Recovery Demo Guide
## Prep
Prior to testing collect the following information from the deployment:
From rg-\<nameID>
traf-\<namdID> collect DNS name
vm-\<namdID>-1 and vm-\<namdID>-1 collect Public IP address
From rg-\<nameID>-asr
pip-dr-<namdID>-1 amd pip-dr-<namdID>-2

## Pre-Failover Test
Open a web browser and connect on port 80 to the DNS name of the traffic manager and both VM public IPs. VMs should display their own name and the region they are running from. Traffic Manager should rotate between both servers

## Test Failover
In the Azure Portal browse to a demo VM > Operations > Disaster Recovery. Along the top menu bar select Test Failover. Use teh default settings for test.
Monitor the from portal. Once failover is complete connect to the relevant pubic IP address of the failed over server from a web browser on port 80. Server nam should be dispalyed with the recovery region.
In Azure portal select Clean Up Failover

## Live Failover
In the Azure Portal browse to a demo VM > Operations > Disaster Recovery. Along the top menu bar select Failover. Check that you understand the risk and continue. Check to shutdown machine before failing over/
Monitor from portal. Once failover is complete connect to Traffic Manager to show that user connection path remains the same. If only one server is failed over interface should rotate between regions.
## Naming

All resource names are based off the nameID paramater. The default value is teh current date/time in yyMMddHHmm. The format of all names is:

\<type>-\<nameID>-\<suffix>

Type denotes the resource type using [Microsoft provided abbriviations](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations).

##