# Install the required module for Excel export
Install-Module -Name ImportExcel -Force -Scope CurrentUser

Import-Module -Name Az
Import-Module -Name ImportExcel

param (
    [string]$TenantId,
    [string[]]$SubscriptionIds,
    [string]$OutputPath = "./AzureVmReport.xlsx",
    [string]$VmNameExcludePattern = "vmftpw11ss*"
)

# Function to guess the role based on VM name
function Guess-Role($vmName) {
    if ($vmName -match "web") { return "Web Server" }
    elseif ($vmName -match "db") { return "Database Server" }
    elseif ($vmName -match "app") { return "Application Server" }
    else { return "Unknown Role" }
}

# Function to get cost for a VM
function Get-VmCost($vmId) {
    $endDate = (Get-Date).AddDays(-1)
    $startDate = $endDate.AddMonths(-1).AddDays(1)
    $usageDetails = Get-AzConsumptionUsageDetail -StartDate $startDate -EndDate $endDate

    $vmCost = $usageDetails | Where-Object { $_.InstanceId -eq $vmId } | Measure-Object -Property PretaxCost -Sum
    return [math]::Round($vmCost.Sum, 2)
}

$report = @()

# Connect to the specific tenant
Connect-AzAccount -TenantId $TenantId

foreach ($subscriptionId in $SubscriptionIds) {
    Set-AzContext -SubscriptionId $subscriptionId

    # Get all VMs in the subscription
    $vms = Get-AzVM
    foreach ($vm in $vms) {
        # Exclude VMs starting with specified pattern
        if ($vm.Name -like $VmNameExcludePattern) {
            continue
        }

        $vmName = $vm.Name
        $role = Guess-Role -vmName $vmName
        $subscriptionName = (Get-AzSubscription -SubscriptionId $subscriptionId).Name

        # Get VNET and Subnet
        $networkInterface = Get-AzNetworkInterface -ResourceGroupName $vm.ResourceGroupName -Name $vm.NetworkProfile.NetworkInterfaces[0].Id.Split('/')[-1]
        $vnet = $networkInterface.IpConfigurations[0].Subnet.Id.Split('/')[-3]
        $subnet = $networkInterface.IpConfigurations[0].Subnet.Id.Split('/')[-1]

        # Get current size
        $currentSize = $vm.HardwareProfile.VmSize

        # Get current monthly cost
        $vmId = $vm.Id
        $currentMonthlyCost = Get-VmCost -vmId $vmId

        # Get current power state
        $powerState = (Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Status).Statuses | Where-Object { $_.Code -like 'PowerState/*' }

        # Get disks and their tiers
        $osDisk = Get-AzDisk -ResourceGroupName $vm.ResourceGroupName -DiskName $vm.StorageProfile.OsDisk.Name
        $osDiskInfo = "$($osDisk.Name) ($($osDisk.Sku.Name))"

        $dataDisks = @()
        foreach ($dataDisk in $vm.StorageProfile.DataDisks) {
            $disk = Get-AzDisk -ResourceGroupName $vm.ResourceGroupName -DiskName $dataDisk.Name
            $diskInfo = "$($disk.Name) ($($disk.Sku.Name))"
            $dataDisks += $diskInfo
        }
        $diskInfoString = $osDiskInfo + ", " + ($dataDisks -join ", ")

        $report += [pscustomobject]@{
            'Virtual Machine Name' = $vmName
            'Role'                 = $role
            'Subscription'         = $subscriptionName
            'VNET\SNET'            = "$vnet\$subnet"
            'Current Size'         = $currentSize
            'Current Monthly Cost' = $currentMonthlyCost
            'Power State'          = $powerState.DisplayStatus
            'Assigned Disks'       = $diskInfoString
        }
    }
}

# Export to Excel
$report | Export-Excel -Path $OutputPath -AutoSize -Title "Azure VM Report"
