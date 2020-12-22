#Failback to the original zone
$sourceresourcegroupname="ASRfailover"
$vmname="myvmname"
$recoveryvaultname="recoveryvault"
$resourcegroupname="ASR"
$fabric_zone="westeurope"
$ProtectionContainername="zone2"

#This step simulates a failure of the VM otherwise 2 same vm's will run in the same vnet with the same IP.
Stop-AzVM -ResourceGroupName $sourceresourcegroupname -Name $vmname

#Get recovery vault
$vault = Get-AzRecoveryServicesVault -Name $recoveryvaultname -ResourceGroupName $resourcegroupname

#Setting the vault context.
Set-AzRecoveryServicesAsrVaultContext -Vault $vault

#Get fabric
$PrimaryFabric = Get-AzRecoveryServicesAsrFabric -Name $fabric_zone

#Get container
$ProtContainer = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $PrimaryFabric -Name $ProtectionContainername

#Get protectedItem
$ReplicationProtectedItem = Get-AzRecoveryServicesAsrReplicationProtectedItem -FriendlyName $vmname -ProtectionContainer $ProtContainer

#Recoverypoints
$RecoveryPoints = Get-AzRecoveryServicesAsrRecoveryPoint -ReplicationProtectedItem $ReplicationProtectedItem

#The list of recovery points returned may not be sorted chronologically and will need to be sorted first, in order to be able to find the oldest or the latest recovery points for the virtual machine.
"{0} {1}" -f $RecoveryPoints[0].RecoveryPointType, $RecoveryPoints[-1].RecoveryPointTime

#Start the fail over job
$Job_Failover = Start-AzRecoveryServicesAsrUnplannedFailoverJob -ReplicationProtectedItem $ReplicationProtectedItem -Direction PrimaryToRecovery -RecoveryPoint $RecoveryPoints[-1]

do {
        $Job_Failover = Get-AzRecoveryServicesAsrJob -Job $Job_Failover;
        start-sleep 30;
} while (($Job_Failover.State -eq "InProgress") -or ($JobFailover.State -eq "NotStarted"))

$Job_Failover.State

$CommitFailoverJOb = Start-AzRecoveryServicesAsrCommitFailoverJob -ReplicationProtectedItem $ReplicationProtectedItem

Get-AzRecoveryServicesAsrJob -Job $CommitFailoverJob