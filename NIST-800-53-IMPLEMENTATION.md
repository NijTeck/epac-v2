# NIST SP 800-53 Rev. 5 Implementation Guide

## Overview

Comprehensive NIST 800-53 Rev. 5 compliance implementation using Azure Policy and EPAC (Enterprise Azure Policy as Code).

**Coverage**: 698 built-in Microsoft policies + 5 custom enforcement policies = **Complete automated enforcement** for Azure resources.

## Quick Start

### Deploy Everything

```powershell
# 1. Deploy via EPAC
Build-DeploymentPlans -PacEnvironmentSelector "epac-dev"
Deploy-PolicyPlan -PacEnvironmentSelector "epac-dev"
Deploy-RolesPlan -PacEnvironmentSelector "epac-dev"

# 2. Create remediation tasks for existing resources
Start-AzPolicyRemediation -Name "nist-remediation" `
    -PolicyAssignmentId "/providers/Microsoft.Management/managementGroups/<mg-id>/providers/Microsoft.Authorization/policyAssignments/nist-800-53-r5-comprehensive" `
    -ManagementGroupName "<mg-id>"
```

## What's Included

### Policy Definitions (by Control Family)

**SI - System and Information Integrity**
- Auto-deploy Defender for Cloud plans (App Services, SQL, Storage, Containers, Key Vault, ARM, DNS, Databases, Cosmos DB)
- Configure security contacts (esere@lanl.gov, all alerts)
- Deploy vulnerability assessment on VMs

**CM - Configuration Management**
- Windows STIG compliance audit
- Linux STIG compliance audit

### Policy Set

`comprehensive-nist-800-53-r5` includes:
- 698 Microsoft built-in NIST policies
- 5 custom enforcement policies
- Guest Configuration prerequisites

### Assignment

Single assignment: `nist-800-53-r5-comprehensive`
- Scope: Management Group root
- Identity: System-assigned managed identity
- Security Contact: esere@lanl.gov

## Key Configurations

### Defender for Cloud

| Plan | Status | Reason |
|------|--------|--------|
| Servers | **DISABLED** | Using CrowdStrike |
| App Services | Enabled | |
| SQL Servers | Enabled | |
| SQL Server VMs | Enabled | |
| Storage | Enabled | V2 |
| Containers | Enabled | |
| Key Vault | Enabled | |
| Resource Manager | Enabled | |
| DNS | Enabled | |
| Open-Source Databases | Enabled | |
| Cosmos DB | Enabled | |

### Security Contacts

- **Email**: esere@lanl.gov
- **Alert Severity**: Low (all alerts)
- **Notify Admins**: Yes

### STIG Compliance

- **Windows**: Enabled (AuditIfNotExists)
- **Linux**: Enabled (AuditIfNotExists)
- **Arc Machines**: Disabled

## File Structure

```
Definitions/
├── policyDefinitions/
│   ├── CM-ConfigurationManagement/
│   │   ├── custom-cm-windows-stig-compliance.json
│   │   └── custom-cm-linux-stig-compliance.json
│   ├── SI-SystemAndInformationIntegrity/
│   │   ├── custom-si-defender-plans-deployment.json
│   │   ├── custom-si-security-contacts.json
│   │   └── custom-si-vulnerability-assessment.json
│   └── [18 other control family folders]
├── policySetDefinitions/
│   └── comprehensive-nist-800-53-r5.jsonc
├── policyAssignments/
│   ├── comprehensive-nist-800-53-assignment.jsonc
│   └── guest-configuration-prerequisites.jsonc
└── policyExemptions/
    └── defender-for-servers-crowdstrike-exemption.jsonc
```

## Exemptions

**Defender for Servers**: Exempted - Using CrowdStrike Falcon for endpoint protection (SI-3, SI-4)

## Monitoring

### Check Compliance

```powershell
# Overall compliance
Get-AzPolicyStateSummary -ManagementGroupName "<mg-id>"

# Non-compliant resources
Get-AzPolicyState -ManagementGroupName "<mg-id>" -Filter "ComplianceState eq 'NonCompliant'"

# Defender plans status
Get-AzSecurityPricing -SubscriptionId "<sub-id>"

# Security contacts
Get-AzSecurityContact -SubscriptionId "<sub-id>"
```

### Remediation

```powershell
# Check remediation tasks
Get-AzPolicyRemediation -ManagementGroupName "<mg-id>"

# Create new remediation
Start-AzPolicyRemediation -Name "remediation-$(Get-Date -Format 'yyyyMMdd')" `
    -PolicyAssignmentId "<assignment-id>" `
    -ManagementGroupName "<mg-id>"
```

## Troubleshooting

### Managed Identity Permissions

```powershell
# Check role assignments
$assignment = Get-AzPolicyAssignment -Name "nist-800-53-r5-comprehensive"
Get-AzRoleAssignment -ObjectId $assignment.Identity.PrincipalId

# Assign Security Admin role if missing
New-AzRoleAssignment `
    -ObjectId $assignment.Identity.PrincipalId `
    -RoleDefinitionName "Security Admin" `
    -Scope "/providers/Microsoft.Management/managementGroups/<mg-id>"
```

### Guest Configuration Issues

Ensure prerequisites are deployed:
```powershell
# Check Guest Configuration assignment
Get-AzPolicyAssignment -Name "guest-config-prereq"

# Create remediation for prerequisites
Start-AzPolicyRemediation -Name "guest-config-remediation" `
    -PolicyAssignmentId "<guest-config-assignment-id>" `
    -ManagementGroupName "<mg-id>"
```

## Control Coverage

| Family | Coverage | Notes |
|--------|----------|-------|
| AC - Access Control | 80% | Network isolation, private endpoints, managed identities |
| AU - Audit & Accountability | 90% | Diagnostic settings, Log Analytics |
| CM - Configuration Management | 75% | Baselines, STIG compliance, required tags |
| IA - Identity & Authentication | 65% | Requires Entra ID for MFA, PIM |
| SC - System & Communications Protection | 85% | TLS, encryption, network security |
| SI - System & Information Integrity | 80% | Defender for Cloud, vulnerability assessment |

## References

- [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final)
- [EPAC Documentation](https://azure.github.io/enterprise-azure-policy-as-code/)
- [Microsoft Defender for Cloud](https://learn.microsoft.com/en-us/azure/defender-for-cloud/)
- [Azure Policy](https://learn.microsoft.com/en-us/azure/governance/policy/)
