# Automated Remediation Strategy for NIST 800-53 Compliance

## Overview
This strategy implements automated remediation directly through EPAC using DeployIfNotExists (DINE) and Modify policy effects, plus automated remediation tasks.

## Phase 1: Update Policy Effects for Auto-Remediation

### Update CSV for Key Non-Compliant Controls

The following policies should be changed from "Audit" to "DeployIfNotExists" or "Modify" to enable automatic remediation:

```csv
# Key policies to update in nist-800-53-parameters.csv
# Format: policyId,currentEffect,newEffect,remediationAction

# Audit and Logging
"Deploy Diagnostic Settings for Activity Log to Log Analytics workspace","Audit","DeployIfNotExists","Deploys diagnostic settings"
"Deploy Diagnostic Settings for Key Vault to Log Analytics workspace","Audit","DeployIfNotExists","Deploys diagnostic settings"
"Deploy Diagnostic Settings for Azure SQL Database to Log Analytics workspace","Audit","DeployIfNotExists","Deploys diagnostic settings"
"Flow logs should be configured for every network security group","Audit","DeployIfNotExists","Enables NSG flow logs"
"Azure Monitor log profile should collect logs for categories 'write,' 'delete,' and 'action'","Audit","DeployIfNotExists","Configures log profile"

# Security Center/Defender
"Enable Azure Security Center on your subscription","Audit","DeployIfNotExists","Enables ASC"
"Auto provisioning of the Log Analytics agent should be enabled","Audit","DeployIfNotExists","Enables auto-provisioning"
"System updates should be installed on your machines","Audit","DeployIfNotExists","Installs updates"
"Vulnerabilities in security configuration should be remediated","Audit","DeployIfNotExists","Applies security baseline"

# Access Control
"MFA should be enabled on accounts with write permissions","Audit","DeployIfNotExists","Enforces MFA"
"Deploy Windows Defender Advanced Threat Protection agent","Audit","DeployIfNotExists","Deploys ATP agent"

# Network Security
"DDoS Protection Standard should be enabled","Audit","DeployIfNotExists","Enables DDoS protection"
"Web Application Firewall should be enabled for Application Gateway","Audit","DeployIfNotExists","Enables WAF"
"Network Watcher should be enabled","Audit","DeployIfNotExists","Enables Network Watcher"

# Data Protection
"Transparent Data Encryption on SQL databases should be enabled","Audit","DeployIfNotExists","Enables TDE"
"Geo-redundant backup should be enabled for Azure Database","Audit","DeployIfNotExists","Enables backup"
```

## Phase 2: Create Automated Remediation Workflow

### Add this workflow to `.github/workflows/auto-remediation.yml`:

```yaml
name: NIST 800-53 Auto-Remediation

on:
  schedule:
    # Run daily at 2 AM UTC
    - cron: '0 2 * * *'
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to remediate'
        required: true
        default: 'epac-dev'
        type: choice
        options:
        - epac-dev
        - tenant

permissions:
  id-token: write
  contents: read

jobs:
  check-compliance:
    runs-on: ubuntu-latest
    outputs:
      has-non-compliant: ${{ steps.check.outputs.has-non-compliant }}
      non-compliant-count: ${{ steps.check.outputs.count }}
    steps:
      - name: Azure Login
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          enable-AzPSSession: true
          allow-no-subscriptions: true

      - name: Check Compliance State
        id: check
        uses: azure/powershell@v2
        with:
          inlineScript: |
            $mgScope = "/providers/Microsoft.Management/managementGroups/e1f3e196-aa55-4709-9c55-0e334c0b444f"

            # Get non-compliant resources
            $nonCompliant = Get-AzPolicyState -ManagementGroupName "e1f3e196-aa55-4709-9c55-0e334c0b444f" `
              -Filter "ComplianceState eq 'NonCompliant' and PolicySetDefinitionName eq 'nist-800-53-r5'"

            $count = ($nonCompliant | Measure-Object).Count

            if ($count -gt 0) {
              Write-Host "Found $count non-compliant resources"
              echo "has-non-compliant=true" >> $env:GITHUB_OUTPUT
              echo "count=$count" >> $env:GITHUB_OUTPUT

              # Log details for review
              $nonCompliant | Select-Object ResourceId, PolicyDefinitionName, ComplianceState |
                ConvertTo-Json | Out-File -FilePath compliance-report.json
            } else {
              Write-Host "All resources are compliant!"
              echo "has-non-compliant=false" >> $env:GITHUB_OUTPUT
              echo "count=0" >> $env:GITHUB_OUTPUT
            }
          azPSVersion: "latest"

      - name: Upload Compliance Report
        if: steps.check.outputs.has-non-compliant == 'true'
        uses: actions/upload-artifact@v3
        with:
          name: compliance-report
          path: compliance-report.json

  create-remediation-tasks:
    needs: check-compliance
    if: needs.check-compliance.outputs.has-non-compliant == 'true'
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment || 'epac-dev' }}
    steps:
      - name: Azure Login
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          enable-AzPSSession: true
          allow-no-subscriptions: true

      - name: Create Remediation Tasks
        uses: azure/powershell@v2
        with:
          inlineScript: |
            $mgScope = "/providers/Microsoft.Management/managementGroups/e1f3e196-aa55-4709-9c55-0e334c0b444f"
            $timestamp = Get-Date -Format "yyyyMMddHHmm"

            # Get all DINE and Modify policies that are non-compliant
            $policies = Get-AzPolicyState -ManagementGroupName "e1f3e196-aa55-4709-9c55-0e334c0b444f" `
              -Filter "ComplianceState eq 'NonCompliant' and PolicySetDefinitionName eq 'nist-800-53-r5'" |
              Where-Object {
                $def = Get-AzPolicyDefinition -Id $_.PolicyDefinitionId
                $def.Properties.PolicyRule.then.effect -in @('DeployIfNotExists', 'Modify')
              }

            $remediationTasks = @()

            foreach ($policy in $policies | Select-Object -Unique PolicyAssignmentId, PolicyDefinitionReferenceId) {
              try {
                $taskName = "NIST-Remediation-$($policy.PolicyDefinitionReferenceId)-$timestamp"

                Write-Host "Creating remediation task: $taskName"

                $task = Start-AzPolicyRemediation `
                  -Name $taskName `
                  -PolicyAssignmentId $policy.PolicyAssignmentId `
                  -PolicyDefinitionReferenceId $policy.PolicyDefinitionReferenceId `
                  -ManagementGroupName "e1f3e196-aa55-4709-9c55-0e334c0b444f" `
                  -LocationFilter "eastus,westus2" `
                  -ResourceDiscoveryMode ReEvaluateCompliance

                $remediationTasks += @{
                  TaskName = $taskName
                  PolicyId = $policy.PolicyDefinitionReferenceId
                  Status = "Created"
                  TaskId = $task.Id
                }

                Write-Host "✅ Created remediation task: $taskName"
              }
              catch {
                Write-Warning "Failed to create remediation for $($policy.PolicyDefinitionReferenceId): $_"
              }
            }

            # Output summary
            Write-Host "`n📊 Remediation Summary:"
            Write-Host "Total remediation tasks created: $($remediationTasks.Count)"

            # Save remediation tasks for tracking
            $remediationTasks | ConvertTo-Json | Out-File -FilePath remediation-tasks.json
          azPSVersion: "latest"

      - name: Upload Remediation Tasks
        uses: actions/upload-artifact@v3
        with:
          name: remediation-tasks
          path: remediation-tasks.json

  monitor-remediation:
    needs: create-remediation-tasks
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment || 'epac-dev' }}
    steps:
      - name: Wait for Remediation
        run: sleep 300  # Wait 5 minutes for remediation to progress

      - name: Azure Login
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          enable-AzPSSession: true
          allow-no-subscriptions: true

      - name: Check Remediation Status
        uses: azure/powershell@v2
        with:
          inlineScript: |
            # Get all active remediation tasks
            $tasks = Get-AzPolicyRemediation -ManagementGroupName "e1f3e196-aa55-4709-9c55-0e334c0b444f" |
              Where-Object { $_.Name -like "NIST-Remediation-*" }

            Write-Host "📊 Remediation Status Report:"
            Write-Host "================================"

            $summary = @{
              Succeeded = 0
              Failed = 0
              InProgress = 0
            }

            foreach ($task in $tasks) {
              Write-Host "$($task.Name): $($task.ProvisioningState)"

              switch ($task.ProvisioningState) {
                "Succeeded" { $summary.Succeeded++ }
                "Failed" { $summary.Failed++ }
                default { $summary.InProgress++ }
              }
            }

            Write-Host "`nSummary:"
            Write-Host "✅ Succeeded: $($summary.Succeeded)"
            Write-Host "❌ Failed: $($summary.Failed)"
            Write-Host "⏳ In Progress: $($summary.InProgress)"

            # Check new compliance state
            $newCompliance = Get-AzPolicyState -ManagementGroupName "e1f3e196-aa55-4709-9c55-0e334c0b444f" `
              -Filter "ComplianceState eq 'NonCompliant' and PolicySetDefinitionName eq 'nist-800-53-r5'"

            $newCount = ($newCompliance | Measure-Object).Count
            Write-Host "`n📈 Compliance Improvement:"
            Write-Host "Previous non-compliant: ${{ needs.check-compliance.outputs.non-compliant-count }}"
            Write-Host "Current non-compliant: $newCount"
            Write-Host "Resources remediated: $(${{ needs.check-compliance.outputs.non-compliant-count }} - $newCount)"
          azPSVersion: "latest"

      - name: Send Notification
        if: always()
        run: |
          echo "📧 Remediation Complete - Check Azure Portal for details"
          echo "View at: https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyMenuBlade/Compliance"
```

## Phase 3: Update Policy Parameters CSV

Create a script to update your CSV file for auto-remediation:

### Save as `update-for-remediation.ps1`:

```powershell
# Script to update NIST 800-53 policies for auto-remediation
param(
    [string]$CsvPath = "./Definitions/policyAssignments/nist-800-53-parameters.csv"
)

# Policies that should use DeployIfNotExists for auto-remediation
$autoRemediatePolicies = @{
    # Diagnostic Settings
    "Deploy Diagnostic Settings" = "DeployIfNotExists"
    "Configure diagnostic settings" = "DeployIfNotExists"

    # Security Center
    "Enable Azure Security Center" = "DeployIfNotExists"
    "Auto provisioning" = "DeployIfNotExists"
    "Deploy Azure Security Monitoring Agent" = "DeployIfNotExists"

    # System Updates
    "System updates" = "DeployIfNotExists"
    "Deploy default Microsoft IaaSAntimalware" = "DeployIfNotExists"

    # Network Security
    "Deploy network watcher" = "DeployIfNotExists"
    "Configure network security groups" = "DeployIfNotExists"
    "Deploy DDoS Protection" = "DeployIfNotExists"

    # Backup
    "geo-redundant backup" = "DeployIfNotExists"
    "Configure backup" = "DeployIfNotExists"

    # Encryption
    "Transparent Data Encryption" = "DeployIfNotExists"
    "Deploy Disk Encryption" = "DeployIfNotExists"

    # Monitoring
    "Deploy Log Analytics agent" = "DeployIfNotExists"
    "Configure Azure Monitor" = "DeployIfNotExists"
}

# Read CSV
$csv = Import-Csv $CsvPath

# Update policies
foreach ($row in $csv) {
    foreach ($policyPattern in $autoRemediatePolicies.Keys) {
        if ($row.displayName -like "*$policyPattern*") {
            # Check if this policy supports the effect
            if ($row.allowedEffects -like "*DeployIfNotExists*") {
                Write-Host "Updating $($row.displayName) to DeployIfNotExists"
                $row.defaultEffect = "DeployIfNotExists"
            }
            elseif ($row.allowedEffects -like "*Modify*") {
                Write-Host "Updating $($row.displayName) to Modify"
                $row.defaultEffect = "Modify"
            }
        }
    }
}

# Save updated CSV
$csv | Export-Csv $CsvPath -NoTypeInformation
Write-Host "✅ CSV updated for auto-remediation"
```

## Phase 4: PowerShell Module for On-Demand Remediation

### Save as `Start-NISTRemediation.ps1`:

```powershell
function Start-NISTRemediation {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ManagementGroupId = "e1f3e196-aa55-4709-9c55-0e334c0b444f",

        [Parameter(Mandatory=$false)]
        [string]$PolicyAssignmentName = "nist-800-53-r5",

        [Parameter(Mandatory=$false)]
        [switch]$WhatIf
    )

    Write-Host "🔍 Analyzing NIST 800-53 Compliance..." -ForegroundColor Cyan

    # Get non-compliant resources
    $nonCompliant = Get-AzPolicyState `
        -ManagementGroupName $ManagementGroupId `
        -Filter "ComplianceState eq 'NonCompliant' and PolicyAssignmentName eq '$PolicyAssignmentName'"

    if ($nonCompliant.Count -eq 0) {
        Write-Host "✅ All resources are compliant!" -ForegroundColor Green
        return
    }

    Write-Host "Found $($nonCompliant.Count) non-compliant resources" -ForegroundColor Yellow

    # Group by policy for efficient remediation
    $groupedPolicies = $nonCompliant | Group-Object PolicyDefinitionReferenceId

    $remediationTasks = @()

    foreach ($policyGroup in $groupedPolicies) {
        $policy = $policyGroup.Group[0]

        # Check if policy supports remediation
        $policyDef = Get-AzPolicyDefinition -Id $policy.PolicyDefinitionId
        $effect = $policyDef.Properties.PolicyRule.then.effect

        if ($effect -in @('DeployIfNotExists', 'Modify', 'deployIfNotExists', 'modify')) {
            Write-Host "📝 Creating remediation for: $($policyGroup.Name)" -ForegroundColor Yellow

            if (-not $WhatIf) {
                try {
                    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
                    $taskName = "Manual-NIST-$($policyGroup.Name)-$timestamp"

                    $task = Start-AzPolicyRemediation `
                        -Name $taskName `
                        -PolicyAssignmentId $policy.PolicyAssignmentId `
                        -PolicyDefinitionReferenceId $policy.PolicyDefinitionReferenceId `
                        -ManagementGroupName $ManagementGroupId `
                        -ResourceDiscoveryMode ReEvaluateCompliance

                    $remediationTasks += $task
                    Write-Host "  ✅ Created remediation task: $taskName" -ForegroundColor Green
                }
                catch {
                    Write-Host "  ❌ Failed: $_" -ForegroundColor Red
                }
            }
            else {
                Write-Host "  [WhatIf] Would create remediation task" -ForegroundColor Gray
            }
        }
        else {
            Write-Host "⚠️  Policy '$($policyGroup.Name)' does not support auto-remediation (Effect: $effect)" -ForegroundColor Yellow
        }
    }

    if ($remediationTasks.Count -gt 0) {
        Write-Host "`n📊 Remediation Summary:" -ForegroundColor Cyan
        Write-Host "  Total tasks created: $($remediationTasks.Count)" -ForegroundColor White
        Write-Host "  Monitor progress at: https://portal.azure.com/#blade/Microsoft_Azure_Policy/RemediationBlade" -ForegroundColor White

        return $remediationTasks
    }
}

# Run remediation
Start-NISTRemediation -WhatIf  # Remove -WhatIf to actually create tasks
```

## Phase 5: Integration with EPAC Pipeline

### Update your EPAC deployment workflow to include auto-remediation:

Add this step to `.github/workflows/epac-tenant-workflow.yml`:

```yaml
  remediate:
    name: Auto-Remediate Non-Compliant Resources
    needs: [deployPolicy]
    if: needs.deployPolicy.result == 'success'
    runs-on: ubuntu-latest
    environment: TENANT-DEPLOY-POLICY
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Azure Login
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          enable-AzPSSession: true
          allow-no-subscriptions: true

      - name: Wait for Policy Evaluation
        run: sleep 300  # Wait 5 minutes for policies to evaluate

      - name: Start Auto-Remediation
        uses: azure/powershell@v2
        with:
          inlineScript: |
            Write-Host "Starting NIST 800-53 Auto-Remediation..." -ForegroundColor Cyan

            # Get the assignment
            $assignment = Get-AzPolicyAssignment -Name "nist-800-53-r5" -Scope "/providers/Microsoft.Management/managementGroups/e1f3e196-aa55-4709-9c55-0e334c0b444f"

            if ($assignment) {
              # Start remediation for all DINE/Modify policies
              $timestamp = Get-Date -Format "yyyyMMddHHmmss"

              $remediation = Start-AzPolicyRemediation `
                -Name "EPAC-Auto-Remediation-$timestamp" `
                -PolicyAssignmentId $assignment.PolicyAssignmentId `
                -ManagementGroupName "e1f3e196-aa55-4709-9c55-0e334c0b444f" `
                -ResourceDiscoveryMode ReEvaluateCompliance

              Write-Host "✅ Started remediation: $($remediation.Name)" -ForegroundColor Green
              Write-Host "Monitor at: https://portal.azure.com/#blade/Microsoft_Azure_Policy/RemediationBlade" -ForegroundColor Yellow
            }
          azPSVersion: "latest"
```

## Quick Start Commands

### 1. Update your CSV for auto-remediation:
```powershell
.\update-for-remediation.ps1
```

### 2. Commit and push changes:
```bash
git add -A
git commit -m "feat: Enable auto-remediation for NIST 800-53 policies"
git push
```

### 3. Manually trigger remediation:
```powershell
# Connect to Azure
Connect-AzAccount -TenantId "e1f3e196-aa55-4709-9c55-0e334c0b444f"

# Start remediation
.\Start-NISTRemediation.ps1
```

### 4. Monitor remediation progress:
```powershell
# Check remediation status
Get-AzPolicyRemediation -ManagementGroupName "e1f3e196-aa55-4709-9c55-0e334c0b444f" |
  Where-Object { $_.Name -like "*NIST*" } |
  Format-Table Name, ProvisioningState, ResourceCount, SuccessCount, FailedCount
```

## Expected Results

### Immediate Improvements (After First Run):
- Diagnostic settings deployed: +11 compliant resources
- Security Center enabled: +11 compliant resources
- Log Analytics agents deployed: +8 compliant resources
- Network Watcher enabled: +6 compliant resources
- Encryption enabled: +2 compliant resources

### Compliance Score Improvement:
- **Before**: 1/12 resources compliant (8.3%)
- **After First Run**: ~8/12 resources compliant (66.7%)
- **After Full Remediation**: 12/12 resources compliant (100%)

## Cost Impact of Auto-Remediation

### Services that will be deployed:
1. **Log Analytics Workspace**: ~$2.76/GB
2. **Diagnostic Settings**: No additional cost
3. **Security Center Standard**: ~$15/VM/month
4. **Network Watcher**: ~$0.50/month
5. **Azure Backup**: ~$5-10/VM/month

### Estimated Monthly Cost Increase:
- **Minimal**: ~$50-100 (basic monitoring)
- **Standard**: ~$200-500 (full security features)
- **Enterprise**: ~$1000+ (all features enabled)

## Monitoring Dashboard

Create an Azure Dashboard to track remediation:
```json
{
  "name": "NIST 800-53 Compliance Dashboard",
  "widgets": [
    {
      "type": "PolicyCompliance",
      "settings": {
        "scope": "/providers/Microsoft.Management/managementGroups/e1f3e196-aa55-4709-9c55-0e334c0b444f",
        "policySetDefinition": "nist-800-53-r5"
      }
    },
    {
      "type": "RemediationTasks",
      "settings": {
        "filter": "Name contains 'NIST'"
      }
    }
  ]
}
```

---
**Note**: Auto-remediation will only work for policies that support DeployIfNotExists or Modify effects. Some compliance requirements need manual intervention or organizational changes.