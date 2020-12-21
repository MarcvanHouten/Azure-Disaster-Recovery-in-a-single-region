# Azure Disaster Recovery between availability zones in a single region

This repository provides a code example how to implement Disaster Recovery of Azure Virtual Machines between availability zones in a single region based on 	[Azure Site Recovery (ASR) zone-to-zone](https://docs.microsoft.com/en-us/azure/site-recovery/azure-to-azure-how-to-enable-zone-to-zone-disaster-recovery). 

The example shows how to setup the protection of a virtual machines, how to failover the virtual machine in case of availability zone failure but also how to re-protect the virtual machine so the virtual machine can failback to it's original availability zone when it's restored. This example also includes the use of *Proximity Placement Groups (PPG)* to show that it's also possible to use this DR solution for virtual machines that require to be physically located as close as possible to each other. 

The virtual machine in this example uses a static ip address to demonstrate that the virtual machines keeps the same ip address after the failover and failback and therefore it's also a good solution for applications that cannot handle an ip address change during a DR situation.

This repository provides a couple of Powershell scripts:
1. a script that creates the test environment as a starting point (ASR_CreateTestEnvironment.ps1)
2. a script to configure the ASR protection of the virtual machine to another availability zone (ASR_replicate.ps1)
3. a script to initiate a failover (ASR_failover.ps1)
4. a script to re-protect the virtual machine so it replicates back to the original zone (ASR_re-protect.ps1)
5. and a script to failback the virtual machine to its original zone and ppg (ASR_failback.ps1) 

All scripts are Powershell based because at the time of writing this PPG was only supported through Powershell. The re-protection script is using the ASR REST API because there is a bug (July 2020) in the Powershell cmdlet to configure the re-protection to the other zone correctly. CHECK 

**Notes**
1. Powershell cmdlets are changing over time. It could be that some of the commands will fail because of these changes.
2. Check if the VM you want to protect has resource locks enabled. If the source VM has resource locks remove these first before running the scripts. Otherwise the scripts will fail. 
3. Be carefull using the latest version of an marketplace image because the ASR agent doesn't support always the latest images. See https://docs.microsoft.com/en-us/azure/site-recovery/azure-to-azure-support-matrix to check if your image version is supported 

![Picture of test setup](/images/DRinasingleregion.jpg)
