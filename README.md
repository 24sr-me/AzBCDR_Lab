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
