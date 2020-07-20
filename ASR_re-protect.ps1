#API used: https://docs.microsoft.com/en-us/rest/api/site-recovery/replicationprotectioncontainers/switchprotection
#The failback is done based on the REST API because the powershell is missing this feature


#Create Protection container mapping (for fail back) between the Recovery and Primary Protection Containers with the Replication policy
$ReplicationPolicyName="policyname"
$RecoveryProtectionContainername="zone2"
$fabric_zone="westeurope"
$ProtectionContainername="zone1"

$PrimaryFabric = Get-AzRecoveryServicesAsrFabric -Name $fabric_zone
$ProtContainer = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $PrimaryFabric -Name $ProtectionContainername
$ReplicationPolicy = Get-AzRecoveryServicesAsrPolicy -Name $ReplicationPolicyName
$RecoveryProtContainer = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $PrimaryFabric -Name $RecoveryProtectionContainername

$TempASRJob = New-AzRecoveryServicesAsrProtectionContainerMapping -Name "Zone2toZone1" -Policy $ReplicationPolicy -PrimaryProtectionContainer $RecoveryProtContainer -RecoveryProtectionContainer $ProtContainer

#Track Job status to check for completion
while (($TempASRJob.State -eq "InProgress") -or ($TempASRJob.State -eq "NotStarted")){
        Start-Sleep 10;
        $TempASRJob = Get-AzRecoveryServicesAsrJob -Job $TempASRJob
}

#Check if the Job completed successfully. The updated job state of a successfully completed job should be "Succeeded"
Write-Output $TempASRJob.State

#$Zone2toZone1Mapping = Get-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainer $RecoveryProtContainer -Name "Zone2toZone1"


#Get accesstoken from active Powershell session
$currentAzureContext = Get-AzContext
$azureRmProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile;
$profileClient = New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($azureRmProfile);
$token = $profileClient.AcquireAccessToken($currentAzureContext.Subscription.TenantId).AccessToken;

#Creating the request header.
$Header = @{"authorization" = "bearer $token"}
$Header['Content-Type'] = "application\json"

#Get the values for the url and body
$sourceresourcegroupname="ASR"
$rgId=(Get-AzResourceGroup -Name $sourceresourcegroupname).ResourceId
$Url = "https://management.azure.com/$rgId/providers/Microsoft.RecoveryServices/vaults/recoveryvault/replicationFabrics/westeurope/replicationProtectionContainers/zone1/switchprotection?api-version=2018-07-10"


#Set Recovery services vault context
$recoveryvaultname="recoveryvault"
$location="west Europe"
$vault = New-AzRecoveryServicesVault -Name $recoveryvaultname -ResourceGroupName $sourceresourcegroupname -Location $location
Set-AzRecoveryServicesAsrVaultContext -Vault $vault

#GET Values for the JSON body
$failoverresourcegroupname="ASRfailover"
$vmname="myname"
$recoveryppg="recppg"
$CachestorageAccountname="cacheaccount99"

$ReplicationProtectedItem = Get-AzRecoveryServicesAsrReplicationProtectedItem -FriendlyName $vmname -ProtectionContainer $ProtContainer
$recoveryProximityPlacementGroup = Get-AzProximityPlacementGroup -Name $recoveryppg -ResourceGroupName $sourceresourcegroupname
$CacheStorageAccount=Get-AzStorageAccount -Name $CachestorageAccountname -ResourceGroupName $sourceresourcegroupname
$VM = Get-AzVM -ResourceGroupName $failoverresourcegroupname -Name $vmname
$OSdiskId = $VM.StorageProfile.OsDisk.ManagedDisk.Id

$body = @{
  "properties"= @{
    "replicationProtectedItemName"= $ReplicationProtectedItem.Name
    "providerSpecificDetails" = @{
    "instanceType"= "A2A"
    "recoveryContainerId" =  $ProtContainer.ID
    "recoveryAvailabilityZone" =  "1"
    "recoveryProximityPlacementGroupId" = $recoveryProximityPlacementGroup.Id
    "vmManagedDisks"= @(
		@{
          "diskId"= $OSdiskId
          "primaryStagingAzureStorageAccountId"= $CacheStorageAccount.Id
          "recoveryResourceGroupId"= $rgId
          "recoveryReplicaDiskAccountType"= "Premium_LRS"
          "recoveryTargetDiskAccountType"= "Premium_LRS"
        }
		
		)
      "vmDisks"= @()
      "recoveryResourceGroupId"= $rgId
       "policyId" = $ReplicationPolicy.ID 
    }
  }
}

$BodyJson = ConvertTo-Json -Depth 8 -InputObject $body
$getpd = Invoke-WebRequest -Uri $Url -Headers $Header -Method 'POST' -ContentType "application/json" -Body $BodyJson  -UseBasicParsing