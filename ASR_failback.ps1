#API used: https://docs.microsoft.com/en-us/rest/api/site-recovery/replicationprotectioncontainers/switchprotection
#The failback is done based on the REST API because the powershell is missing this feature

#Get accesstoken from active Powershell session
$currentAzureContext = Get-AzContext

$azureRmProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile;
$profileClient = New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($azureRmProfile);
$token = $profileClient.AcquireAccessToken($currentAzureContext.Subscription.TenantId).AccessToken;

### Creating the request header.
$Header = @{"authorization" = "bearer $token"}
$Header['Content-Type'] = "application\json"


#Get the values for the url and body
$sourceresourcegroupname="ASR"
$rgId=(Get-AzResourceGroup -Name $sourceresourcegroupname).ResourceId

$Url = "https://management.azure.com/$rgId/providers/Microsoft.RecoveryServices/vaults/recoveryvault/replicationFabrics/westeurope/replicationProtectionContainers/zone1/switchprotection?api-version=2018-07-10"

#GET Values for the JSON body
$vmname="myname"
$ProtectionContainername="zone1"
$fabric_zone="westeurope"

$PrimaryFabric = Get-AzRecoveryServicesAsrFabric -Name $fabric_zone
$ProtContainer = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $PrimaryFabric -Name $ProtectionContainername
$ReplicationProtectedItem = Get-AzRecoveryServicesAsrReplicationProtectedItem -FriendlyName $vmname -ProtectionContainer $ProtContainer


$body = @{
  "properties"= @{
    "replicationProtectedItemName"= $ReplicationProtectedItem.Name
    "providerSpecificDetails" = @{
      "instanceType"= "A2A"
      "recoveryContainerId" =  $ProtContainer.ID
     "recoveryAvailabilityZone" =  "1"
     "recoveryProximityPlacementGroupId" = "/subscriptions/302ce6c4-c9fd-41b7-9b92-d41405a15eb6/resourceGroups/ASR/providers/Microsoft.Compute/proximityPlacementGroups/sourceppg"
        "vmManagedDisks"= @(
		@{
          "diskId"= "/subscriptions/302ce6c4-c9fd-41b7-9b92-d41405a15eb6/resourceGroups/ASRfailover/providers/Microsoft.Compute/disks/myname_OsDisk_1_cef57edf6ffc469aaf21ce464fca124f"
          "primaryStagingAzureStorageAccountId"= "/subscriptions/302ce6c4-c9fd-41b7-9b92-d41405a15eb6/resourceGroups/ASR/providers/Microsoft.Storage/storageAccounts/cacheaccount99"
          "recoveryResourceGroupId"= "/subscriptions/302ce6c4-c9fd-41b7-9b92-d41405a15eb6/resourceGroups/ASR"
          "recoveryReplicaDiskAccountType"= "Premium_LRS"
          "recoveryTargetDiskAccountType"= "Premium_LRS"
        }
		
		)
      "vmDisks"= @()
      "recoveryResourceGroupId"= "/subscriptions/302ce6c4-c9fd-41b7-9b92-d41405a15eb6/resourceGroups/ASR"
       "policyId" = "/subscriptions/302ce6c4-c9fd-41b7-9b92-d41405a15eb6/resourceGroups/ASR/providers/Microsoft.RecoveryServices/vaults/recoveryvault/replicationPolicies/policyname"
    }
  }
}

$BodyJson = ConvertTo-Json -Depth 8 -InputObject $body
$getpd = Invoke-WebRequest -Uri $Url -Headers $Header -Method 'POST' -ContentType "application/json" -Body $BodyJson  -UseBasicParsing