# ASR-zone-to-zone-with-ppg

This repository provides a code example how to implement an **Azure zone to zone** Disaster Recovery solution. This example also includes Proximity Placement Groups (PPG) so the Virtual Machine will also failover to another PPG.

This repository provides a couple of Powershell scripts:
1. a script that creates the test environment as a starting point
2. a script to configure the ASR protection of the virtual machine to another availability zone
3. a script to initiate a failover
4. and a script to re-protect the virtual machine so it replicates back to the original VM

All scripts are Powershell based because PPG is only supported through Powershell currently (July 2020). The re-protection script is using the ASR REST API because there is a bug (July 2020) in the Powershell cmdlet to configure the re-protection to the other zone correctly.  

Work in progress:
* The failback of the reverse replicated VM is not included but the code can be copied from the replication script


![Picture of test setup](/images/ASR_zone_to_zone.png)
