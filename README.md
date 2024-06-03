# Azure VM Report Script

This PowerShell script generates a report of virtual machines (VMs) for specified Azure subscriptions and exports it to an Excel file. The report includes details such as VM name, role, subscription, VNET, size, cost, power state, and assigned disks.

## Prerequisites

- [Azure PowerShell Module](https://docs.microsoft.com/en-us/powershell/azure/new-azureps-module-az)
- [ImportExcel Module](https://www.powershellgallery.com/packages/ImportExcel)

## Installation

1. Install the required PowerShell modules:

    ```powershell
    Install-Module -Name Az -AllowClobber -Force
    Install-Module -Name ImportExcel -Force -Scope CurrentUser
    ```

2. Clone this repository or download the script file.

## Usage

1. Connect to your Azure account:

    ```powershell
    Connect-AzAccount
    ```

2. Run the script with the required parameters:

    ```powershell
    .\GenerateAzureVmReport.ps1 -TenantId "your-tenant-id" -SubscriptionIds @("subscription-id-1", "subscription-id-2") -OutputPath "./AzureVmReport.xlsx" -VmNameExcludePattern "vmftpw11ss*"
    ```

## Parameters

- `-TenantId` (string): The Tenant ID to connect to.
- `-SubscriptionIds` (string[]): List of Subscription IDs to target.
- `-OutputPath` (string): Path to save the generated Excel report (default: "./AzureVmReport.xlsx").
- `-VmNameExcludePattern` (string): Pattern to exclude VMs based on their name (default: "vmftpw11ss*").

## Example

```powershell
.\GenerateAzureVmReport.ps1 -TenantId "261c2818-228c-4d49-bb5a-619c4fcd818d" -SubscriptionIds @("389ee01e-5ac8-4b93-9db0-429558adee41", "69d7b980-7927-4913-be05-6c5a53b4fe04") -OutputPath "./AzureVmReport.xlsx" -VmNameExcludePattern "vmftpw11ss*"
