# ASR-zone-to-zone-with-ppg

This repository provides example code how to **failover** an Azure Virtual Machines from one zone to another zone in the same region and from one Proximity Placement Group to another Proximity Placement Group but also show how to **replicate back** the Virtual machine to the original availability zone.

The script to create the test environment is a bash script and uses the Azure CLI. The rest of the scripts that do the replication, failover and failback are using Powershell. This is because ASR doesn't support Azure CLI and because Proximity Placement Groups (PPG) is currently (July 2020) only supported through Powershell

The failback script is using the ASR REST API because there is a bug (July 2020) in the Powershell to configure the failback availability zone correctly.  


![Picture of test setup](/images/ASR_zone_to_zone.png)
