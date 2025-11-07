# NIST 800-53 Coverage Reality with Azure Policy (EPAC)

## Executive Summary

**Bottom Line**: With EPAC driving Azure Policy, you can achieve **60-80% automated enforcement** of NIST 800-53 Rev. 5 technical controls for Azure PaaS/IaaS and AKS workloads.

### Coverage Breakdown

| Category | Coverage | What It Means |
|----------|----------|---------------|
| **Directly Enforceable** | 45-60% | Deny, DeployIfNotExists, Modify, Append at Azure resource plane |
| **Guest Configuration** | 15-25% | VM-level enforcement via Guest Configuration extension |
| **Other Tools Required** | 20-40% | Entra ID, Defender for Cloud, manual processes |

**Total Automated**: ~60-80% for Azure-centric estates
**Manual/Process**: ~20-40% (identity workflows, physical security, training, etc.)

## Why Not 100%?

### The NIST 800-53 Reality

- **NIST Catalog**: 1,100+ controls across 20 families
- **Microsoft's Built-in Initiative**: 698 policy definitions (R5) or 224 (R5.1.1 curated)
- **Coverage**: Even 698 policies represent a **subset** - many controls are narrative or procedural by design

### What Microsoft Says

> "The mapping is not one-to-one and Azure Policy only shows a partial view of compliance. Some controls cannot be automatically assessed or enforced."
> 
> — Microsoft Learn

Defender for Cloud shows **unassessable controls as greyed out** in the regulatory dashboard - these are controls that policy fundamentally cannot decide or enforce.

## What Works Well (Strong Coverage)

### ✅ High Enforcement Families

These control families have **strong Azure Policy coverage** with Deny, DeployIfNotExists, Modify, and Append:

| Family | Controls | Coverage | Examples |
|--------|----------|----------|----------|
| **AC** | Access Control | 70-80% | Network isolation, private endpoints, managed identities |
| **AU** | Audit & Accountability | 85-95% | Diagnostic settings, Log Analytics, activity logs |
| **CM** | Configuration Management | 60-75% | Baseline configs, required tags, allowed resources |
| **SC** | System & Communications Protection | 75-85% | TLS requirements, encryption at rest, network security |
| **SI** | System & Information Integrity | 55-70% | System updates, antimalware, monitoring agents |

### Specific Examples

**Access Control (AC)**:
- AC-4 (Information Flow Enforcement): Network security groups, private endpoints, VNet integration
- AC-6 (Least Privilege): Managed identities, RBAC policies
- AC-17 (Remote Access): Private Link, VPN requirements

**Audit & Accountability (AU)**:
- AU-2 (Event Logging): Diagnostic settings (DeployIfNotExists)
- AU-12 (Audit Record Generation): Activity logs, resource logs

**System & Communications Protection (SC)**:
- SC-7 (Boundary Protection): Network isolation, NSGs, firewalls
- SC-8 (Transmission Confidentiality): TLS 1.2+ requirements
- SC-12 (Cryptographic Key Management): Customer-managed keys
- SC-28 (Protection at Rest): Encryption requirements

**Storage & Data Protection**:
- Encryption at rest (Deny non-encrypted storage)
- Customer-managed keys (DeployIfNotExists)
- Backup requirements (DeployIfNotExists)

**AKS Baselines**:
- Pod security policies
- Network policies
- Container registry restrictions

## What Requires Guest Configuration

### 🔧 VM-Level Controls (15-25%)

Guest Configuration provides **VM-level enforcement** but requires:
1. System-assigned managed identity on VM
2. Guest Configuration extension installed
3. Prerequisite policies deployed first

**Examples**:
- Windows security settings (password policies, audit policies)
- Linux security configurations
- Installed software requirements
- Registry settings
- File system permissions

**Limitation**: Guest Configuration is **detective** (AuditIfNotExists) - it reports non-compliance but doesn't prevent VM creation. It can remediate via DeployIfNotExists for some settings.

## What Cannot Be Enforced by Policy

### ❌ Identity & Authentication (IA) - Partial Coverage

**What Works**:
- Disable local authentication (Deny)
- Require Azure AD authentication (Deny)
- Managed identity requirements (Deny)

**What Doesn't Work** (requires Entra ID):
- MFA enforcement → **Entra Conditional Access**
- Password complexity → **Entra Password Policy**
- Account lifecycle → **Entra Identity Governance**
- Privileged access → **Entra PIM**

### ❌ Physical & Environmental (PE) - No Coverage

**Why**: Azure Policy operates at the **logical resource plane**, not physical infrastructure.

**Examples**:
- PE-2 (Physical Access Authorizations)
- PE-3 (Physical Access Control)
- PE-6 (Monitoring Physical Access)

**Solution**: These are **Microsoft's responsibility** in the shared responsibility model. Document Azure's compliance certifications.

### ❌ Personnel Security (PS) - No Coverage

**Examples**:
- PS-2 (Position Risk Designation)
- PS-3 (Personnel Screening)
- PS-4 (Personnel Termination)

**Solution**: **Organizational HR processes**. Document your procedures.

### ❌ Awareness & Training (AT) - No Coverage

**Examples**:
- AT-2 (Literacy Training and Awareness)
- AT-3 (Role-Based Training)

**Solution**: **Training programs**. Document completion records.

### ❌ Incident Response (IR) - Partial Coverage

**What Works**:
- IR-4 (Incident Handling) - Defender for Cloud alerts (DeployIfNotExists)
- IR-6 (Incident Reporting) - Log collection (DeployIfNotExists)

**What Doesn't Work**:
- IR-2 (Incident Response Training) → **Training program**
- IR-3 (Incident Response Testing) → **Manual exercises**
- IR-8 (Incident Response Plan) → **Documentation**

### ❌ Planning & Program Management (PL, PM) - No Coverage

**Why**: These are **organizational governance** controls, not technical controls.

**Examples**:
- PL-1 (Policy and Procedures)
- PM-1 (Information Security Program Plan)

**Solution**: **Documentation and governance processes**.

## Enforcement Mode Capabilities

### What Each Effect Can Do

| Effect | Capability | Use Cases | Limitations |
|--------|------------|-----------|-------------|
| **Deny** | Block resource creation | Prevent non-compliant configs | Can't fix existing resources |
| **DeployIfNotExists** | Auto-deploy missing configs | Diagnostic settings, extensions | Needs managed identity + RBAC |
| **Modify** | Auto-correct configs | Add tags, change settings | Limited to specific properties |
| **Append** | Add required properties | Tags, network rules | Can't remove properties |
| **Audit** | Report only | Informational monitoring | No enforcement |

### Managed Identity Requirements

**DeployIfNotExists and Modify policies require**:
1. System-assigned managed identity on policy assignment
2. Appropriate RBAC roles (Contributor, specific resource permissions)
3. Remediation tasks for existing resources

**EPAC handles this automatically** when you configure:
```jsonc
"assignment": {
    "identity": {
        "type": "SystemAssigned"
    }
}
```

## Microsoft Defender Plans

**Important**: Defender policies (like "Azure Defender for servers should be enabled") **cannot be enforced via policy**.

**Why**: These policies only **audit** whether Defender plans are enabled. They cannot enable them.

**Solution**: Use the provided script:
```powershell
.\Scripts\Enable-DefenderPlans.ps1 -SubscriptionIds @("sub-id-1", "sub-id-2")
```

**Defender Plans Required for NIST 800-53**:
- Azure Defender for servers (SI-3, SI-4)
- Azure Defender for SQL (SI-3, SI-4)
- Azure Defender for Storage (SI-3, SI-4)
- Azure Defender for Key Vault (SI-4)
- Azure Defender for Resource Manager (SI-4)
- Azure Defender for App Service (SI-3, SI-4)
- Microsoft Defender for Containers (SI-3, SI-4)

## Realistic Implementation Plan

### Phase 1: Core Enforcement (Weeks 1-2)

**Target**: 45-60% coverage

**Focus**:
- Deploy NIST 800-53 policy set with enforcement mode
- Enable high-priority families: AC, SC, AU
- Deploy Defender plans
- Configure diagnostic settings (DeployIfNotExists)

**Expected Result**: Most Azure resources comply with technical controls

### Phase 2: Guest Configuration (Weeks 3-4)

**Target**: +15-25% coverage (total 60-85%)

**Focus**:
- Deploy Guest Configuration prerequisites
- Enable VM-level policies
- Create remediation tasks for existing VMs
- Monitor Guest Configuration compliance

**Expected Result**: VM configurations comply with OS-level controls

### Phase 3: Complementary Tools (Weeks 5-6)

**Target**: +10-15% coverage (total 70-95%)

**Focus**:
- Configure Entra Conditional Access for MFA
- Enable Entra PIM for privileged access
- Configure Defender for Cloud security policies
- Set up Security Center recommendations

**Expected Result**: Identity and access controls enforced

### Phase 4: Documentation & Processes (Weeks 7-8)

**Target**: Remaining 5-30% (manual controls)

**Focus**:
- Document organizational policies (PL, PM)
- Create training programs (AT)
- Establish incident response procedures (IR)
- Document physical security (PE)
- HR processes (PS)

**Expected Result**: Full NIST 800-53 compliance documentation

## Measuring Success

### Automated Enforcement Metrics

```powershell
# Check overall compliance
Get-AzPolicyStateSummary -ManagementGroupName "<your-mg>"

# Calculate enforcement rate
$total = (Get-AzPolicyState -ManagementGroupName "<your-mg>").Count
$compliant = (Get-AzPolicyState -ManagementGroupName "<your-mg>" -Filter "ComplianceState eq 'Compliant'").Count
$complianceRate = [math]::Round(($compliant / $total) * 100, 1)
Write-Host "Compliance Rate: $complianceRate%"
```

### Expected Compliance Rates

| Timeframe | Automated Coverage | Manual Coverage | Total |
|-----------|-------------------|-----------------|-------|
| Week 2 | 45-60% | 0% | 45-60% |
| Week 4 | 60-85% | 0% | 60-85% |
| Week 6 | 70-95% | 0% | 70-95% |
| Week 8 | 70-95% | 5-30% | 100% |

## Control Families Summary

### ✅ Strong Azure Policy Coverage (70-95%)

- **AU** (Audit & Accountability): 85-95%
- **SC** (System & Communications Protection): 75-85%
- **AC** (Access Control): 70-80%
- **CM** (Configuration Management): 60-75%

### 🔧 Moderate Coverage (50-70%)

- **SI** (System & Information Integrity): 55-70%
- **IA** (Identification & Authentication): 50-65% (needs Entra ID)

### ❌ Limited/No Coverage (0-30%)

- **PE** (Physical & Environmental): 0% (Microsoft's responsibility)
- **PS** (Personnel Security): 0% (HR processes)
- **AT** (Awareness & Training): 0% (training programs)
- **PL** (Planning): 10-20% (mostly documentation)
- **PM** (Program Management): 10-20% (mostly documentation)
- **IR** (Incident Response): 30-40% (needs processes + tools)

## Key Takeaways

1. ✅ **60-80% automated enforcement** is realistic for Azure-centric estates
2. ✅ **Strong coverage** for technical controls (AC, AU, CM, SC, SI)
3. ⚠️ **Guest Configuration required** for VM-level controls (15-25%)
4. ⚠️ **Entra ID required** for identity controls (IA family)
5. ❌ **Manual processes required** for organizational controls (PE, PS, AT, PL, PM)
6. ❌ **Defender for Cloud required** for threat detection (SI family)

## References

- Microsoft NIST 800-53 R5 Initiative: 698 policies
- Microsoft NIST 800-53 R5.1.1 Curated: 224 policies
- NIST SP 800-53 Catalog: 1,100+ controls
- Azure Policy Effects: Deny, DeployIfNotExists, Modify, Append, Audit
- Guest Configuration: VM-level compliance
- Entra ID: Identity and access management
- Defender for Cloud: Threat detection and response

## Next Steps

1. ✅ Deploy NIST 800-53 with enforcement mode (already configured)
2. ✅ Deploy Guest Configuration prerequisites (already configured)
3. ⏭️ Enable Microsoft Defender plans (run script)
4. ⏭️ Configure Entra Conditional Access
5. ⏭️ Document manual processes
6. ⏭️ Create training programs
7. ⏭️ Establish incident response procedures

**You're on track for 60-80% automated enforcement!** 🎯
