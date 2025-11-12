# MCSB + NIST 800-53 Enforcement Strategy

## Overview

This document explains the layered security and compliance approach using Microsoft Cloud Security Benchmark (MCSB) for enforcement and NIST SP 800-53 for compliance reporting.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│              Defense-in-Depth Policy Framework              │
└─────────────────────────────────────────────────────────────┘

Layer 1: MCSB Enforcement (226 policies)
├─ Purpose: Preventive + Remediation Controls
├─ Effect Types: Deny, DeployIfNotExists, Modify
├─ Coverage: Azure-specific security controls
└─ Assignment: mcsb-enforcement-assignment.jsonc

Layer 2: NIST 800-53 Compliance (224 policies)
├─ Purpose: Comprehensive compliance framework
├─ Effect Types: Audit, AuditIfNotExists, Deny (66 policies)
├─ Coverage: Federal compliance requirements
└─ Assignment: nist-800-53-assignments.jsonc

Layer 3: Custom Enforcement (5 policies)
├─ Purpose: Gap-filling for NIST controls
├─ Effect Types: DeployIfNotExists
├─ Coverage: SI, CM, IA control families
└─ Assignment: comprehensive-nist-800-53-assignment.jsonc
```

## Why MCSB + NIST?

### MCSB Strengths
✅ **Azure-Native Enforcement**: Built specifically for Azure services
✅ **Preventive Controls**: Heavy use of Deny policies to block non-compliant resources
✅ **Auto-Remediation**: DeployIfNotExists and Modify effects for automatic fixes
✅ **Modern Controls**: Updated frequently with new Azure capabilities
✅ **Defender Integration**: Default policy for Microsoft Defender for Cloud

### NIST 800-53 Strengths
✅ **Regulatory Compliance**: Required for federal/government organizations
✅ **Comprehensive Framework**: Covers all security control families
✅ **Industry Standard**: Widely recognized and audited
✅ **Detailed Mapping**: Maps to other frameworks (ISO, CIS, PCI-DSS)

### The Gap MCSB Fills

NIST 800-53 is a **framework**, not Azure-specific implementation guidance. MCSB provides:

1. **Azure-Specific Controls**:
   - Block creation of VMs with public IPs in production
   - Deny storage accounts without private endpoints
   - Prevent management ports (RDP/SSH) from internet
   - Enforce Azure-specific encryption methods

2. **Preventive Enforcement**:
   - **NIST**: Mostly Audit (report violations after creation)
   - **MCSB**: Deny (prevent violations before creation)

3. **Auto-Remediation**:
   - **NIST**: Limited DeployIfNotExists policies
   - **MCSB**: Extensive DeployIfNotExists coverage

## NIST-to-MCSB Control Mapping

MCSB controls map directly to NIST 800-53 R5. Here are key mappings:

### Network Security (MCSB NS → NIST SC)

| MCSB Control | NIST Control | Effect | Description |
|-------------|-------------|--------|-------------|
| NS-1 | SC-7 | Deny | Segment networks using NSGs |
| NS-2 | SC-7 | Deny | Secure private network connectivity |
| NS-4 | SC-8 | Deny | Protect applications from DDoS |
| NS-6 | SC-7 | DeployIfNotExists | Deploy network monitoring |

### Identity Management (MCSB IM → NIST IA, AC)

| MCSB Control | NIST Control | Effect | Description |
|-------------|-------------|--------|-------------|
| IM-1 | AC-2 | DeployIfNotExists | Use centralized identity (AAD) |
| IM-2 | AC-2 | Audit | Manage application identities |
| IM-3 | IA-2 | Deny | Enforce strong authentication |
| IM-6 | IA-5 | DeployIfNotExists | Manage secrets securely |
| IM-8 | AC-6 | Deny | Restrict privileged access |

### Data Protection (MCSB DP → NIST SC)

| MCSB Control | NIST Control | Effect | Description |
|-------------|-------------|--------|-------------|
| DP-1 | SC-28 | Deny | Encryption at rest (all data) |
| DP-2 | SC-8 | Deny | Encryption in transit (TLS 1.2+) |
| DP-3 | SC-28 | DeployIfNotExists | Monitor data transfer |
| DP-5 | SC-28 | Deny | Use customer-managed keys |

### Logging & Threat Detection (MCSB LT → NIST AU, SI)

| MCSB Control | NIST Control | Effect | Description |
|-------------|-------------|--------|-------------|
| LT-1 | AU-2, AU-12 | DeployIfNotExists | Enable threat detection |
| LT-3 | AU-6 | DeployIfNotExists | Enable logging for resources |
| LT-4 | AU-6 | DeployIfNotExists | Collect network logs |
| LT-5 | AU-6 | DeployIfNotExists | Centralize log management |

### Posture & Vulnerability (MCSB PV → NIST RA, SI)

| MCSB Control | NIST Control | Effect | Description |
|-------------|-------------|--------|-------------|
| PV-1 | RA-5 | DeployIfNotExists | Vulnerability assessments |
| PV-3 | RA-3 | Audit | Security configurations |
| PV-6 | SI-2 | DeployIfNotExists | Patch management |
| PV-7 | RA-5 | DeployIfNotExists | Rapid threat mitigation |

### Asset Management (MCSB AM → NIST CM)

| MCSB Control | NIST Control | Effect | Description |
|-------------|-------------|--------|-------------|
| AM-2 | CM-8 | Modify | Track inventory with tags |
| AM-3 | CM-2 | Audit | Identify authorized services |
| AM-5 | CM-3 | Deny | Restrict resource types/regions |

## Policy Count Breakdown

### MCSB (226 policies)
- **Deny**: ~80 policies (preventive controls)
- **DeployIfNotExists**: ~90 policies (auto-remediation)
- **Modify**: ~20 policies (auto-fix properties)
- **AuditIfNotExists**: ~36 policies (compliance reporting)

### NIST 800-53 (224 policies)
- **Audit**: 158 policies (reporting only)
- **Deny**: 66 policies (we changed from Audit)
- **DeployIfNotExists**: 0 policies (limited remediation)

### Custom (5 policies)
- **DeployIfNotExists**: 5 policies (NIST gap-filling)

**Total: 455 unique policies** (some overlap between MCSB and NIST)

## Enforcement Strategy

### Phase 1: MCSB Enforcement (You Are Here)

Deploy MCSB with default effects to establish baseline Azure security:

```bash
# 1. Commit and push MCSB assignment
git add Definitions/policyAssignments/mcsb-enforcement-assignment.jsonc
git commit -m "Add MCSB enforcement layer for Azure-native security"
git push

# 2. Pipeline deploys MCSB to management group
# 3. Auto-remediation workflow creates remediation tasks
# 4. Review Defender for Cloud compliance dashboard
```

**Expected Outcomes**:
- ✅ Block creation of non-compliant resources (Deny policies)
- ✅ Auto-remediate existing non-compliant resources (DeployIfNotExists)
- ✅ Improve Defender for Cloud secure score
- ✅ Achieve NIST compliance through MCSB control mapping

### Phase 2: Monitor and Tune (Week 1-2)

Monitor for:
- **False Positives**: Legitimate resources blocked by Deny policies
- **Business Impact**: Services affected by enforcement
- **Remediation Failures**: Auto-remediation tasks that fail

Tune by:
1. Override specific policy effects in `mcsb-enforcement-assignment.jsonc`
2. Add exclusions for specific resource groups/subscriptions
3. Adjust parameters for specific policies

### Phase 3: Increase NIST Enforcement (Week 3-4)

Now that MCSB provides baseline Azure security, increase NIST enforcement:

1. **Enable more NIST DeployIfNotExists policies**:
   - Run `Scripts/Enable-EnforcementMode.ps1` again for additional policies
   - Focus on policies not covered by MCSB

2. **Add custom enforcement policies**:
   - Create custom DeployIfNotExists for remaining audit-only NIST controls
   - Focus on application-specific requirements

### Phase 4: Continuous Compliance (Ongoing)

- **Weekly**: Review remediation task results
- **Monthly**: Analyze compliance trends in Defender for Cloud
- **Quarterly**: Update MCSB/NIST assignments with new policy versions

## Auto-Remediation

The auto-remediation workflow (`.github/workflows/auto-remediation.yml`) now handles:

✅ **MCSB remediation**: Creates tasks for MCSB DeployIfNotExists policies
✅ **NIST remediation**: Creates tasks for NIST enforcement policies
✅ **Custom remediation**: Creates tasks for custom enforcement policies

**Workflow triggers**:
- Automatically after EPAC deployment
- Manually via GitHub Actions

**Expected remediation tasks**:
- MCSB: ~90 potential remediation tasks (DeployIfNotExists policies)
- NIST: ~3-5 remediation tasks (custom DeployIfNotExists)
- Total: ~95 concurrent remediation operations

## Compliance Dashboard

### Defender for Cloud View

After deploying MCSB, your Defender for Cloud dashboard will show:

1. **Regulatory Compliance** tab:
   - Microsoft Cloud Security Benchmark (MCSB)
   - NIST SP 800-53 R5
   - Your overall compliance score

2. **Recommendations**:
   - Active recommendations based on MCSB
   - Remediation steps for non-compliant resources
   - Impact of enforcement on secure score

3. **Policy Coverage**:
   - Which NIST controls are covered by MCSB
   - Gaps filled by custom policies
   - Audit vs. enforcement breakdown

### Azure Policy View

Azure Portal > Policy shows:
- **3 Initiatives** assigned to management group:
  1. Microsoft cloud security benchmark (MCSB)
  2. NIST SP 800-53 Rev. 5.1.1 (Built-in)
  3. Comprehensive NIST SP 800-53 Rev. 5 (Custom)

- **Compliance Status** for each:
  - Percentage of compliant resources
  - Count of non-compliant resources
  - Remediation tasks in progress

## Key Differences: MCSB vs NIST

| Aspect | MCSB | NIST 800-53 |
|--------|------|-------------|
| **Purpose** | Azure security implementation | Compliance framework |
| **Scope** | Azure-specific controls | Broad security controls |
| **Effect Focus** | Deny + DeployIfNotExists | Audit + AuditIfNotExists |
| **Update Frequency** | Frequent (Azure releases) | Periodic (NIST revisions) |
| **Compliance Mapping** | Maps TO: NIST, CIS, ISO | Maps FROM: Requirements |
| **Enforcement** | Strong (preventive) | Weak (detective) |
| **Remediation** | Extensive automation | Limited automation |
| **Azure Integration** | Native (Defender default) | External framework |

## Recommendations

### For NIST Compliance

1. **Keep NIST assignment**: Required for regulatory compliance reporting
2. **Deploy MCSB assignment**: Provides Azure-native enforcement
3. **Use BOTH together**: MCSB enforces, NIST reports comprehensive compliance

### For Enforcement

1. **Primary**: MCSB (Deny + DeployIfNotExists)
2. **Secondary**: NIST Deny policies (66 policies we changed)
3. **Tertiary**: Custom DeployIfNotExists (5 policies)

### For Compliance Reporting

1. **Primary**: NIST 800-53 assignment (comprehensive framework)
2. **Secondary**: MCSB compliance dashboard (Azure-specific)
3. **Export**: Use compliance reports for audits

## Common Questions

### Q: Will MCSB conflict with NIST policies?

**A**: No. Azure Policy allows multiple assignments. If both have the same policy with different effects, the most restrictive effect wins (Deny > AuditIfNotExists > Audit).

### Q: Do I still need NIST if I have MCSB?

**A**: Yes, if you need NIST compliance certification. MCSB implements NIST controls for Azure but doesn't replace NIST for compliance reporting.

### Q: How many policies will I have total?

**A**: ~455 unique policies across 3 initiatives (some policies appear in multiple initiatives).

### Q: Will MCSB auto-remediate my NIST violations?

**A**: Yes! MCSB DeployIfNotExists policies will remediate many NIST control violations because MCSB maps to NIST controls.

### Q: Can I use MCSB alone without NIST?

**A**: Yes, if you don't need NIST compliance certification. MCSB provides excellent Azure security without requiring NIST.

### Q: What's the performance impact?

**A**: Minimal. Azure Policy evaluates in real-time during resource creation/modification. The evaluation overhead is negligible.

## Next Steps

1. ✅ Review MCSB assignment configuration
2. ✅ Commit and push to trigger deployment
3. ✅ Monitor deployment in GitHub Actions
4. ✅ Review compliance in Defender for Cloud
5. ✅ Check auto-remediation tasks
6. ✅ Tune policies based on business impact
7. ✅ Document any policy overrides

## References

- [Microsoft Cloud Security Benchmark Overview](https://learn.microsoft.com/en-us/security/benchmark/azure/overview)
- [NIST SP 800-53 R5](https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final)
- [Azure Policy Effects](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/effects)
- [Defender for Cloud Regulatory Compliance](https://learn.microsoft.com/en-us/azure/defender-for-cloud/regulatory-compliance-dashboard)
