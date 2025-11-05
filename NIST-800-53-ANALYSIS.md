# NIST 800-53 Parameters - Empty Policy Effects Analysis

## Executive Summary

**Total Policies with Empty Effects: 117**

This analysis identifies all Azure Policy definitions in the NIST 800-53 parameters that have empty `prodEffect` or `nonprodEffect` fields. Recommendations are provided based on:

1. The policy's `allowedEffects` (what effects the policy supports)
2. The policy's `defaultEffect` (Microsoft's recommended effect)
3. Common Azure Policy patterns and best practices

---

## Results by Recommendation

### 1. **Audit Effect** (10 policies)
- **Policies:** Data encryption and compliance policies that allow Deny/Audit/Disabled
- **Recommendation:** Use `Audit` as the effect
- **Rationale:** These are encryption policies with configurable effects. Audit allows monitoring without blocking resources.
- **Examples:**
  - Cognitive Services accounts should enable data encryption with a customer-managed key
  - Container registries should be encrypted with a customer-managed key
  - SQL servers should use customer-managed keys to encrypt data at rest
  - Storage accounts should use customer-managed key for encryption

### 2. **AuditIfNotExists Effect** (103 policies) - *LARGEST CATEGORY*
- **Policies:** Compliance and audit policies that allow AuditIfNotExists/Disabled
- **Recommendation:** Use `AuditIfNotExists` as the effect
- **Rationale:** These audit policies check for compliance without enforcing action
- **Examples:**
  - App Configuration should use private link
  - Azure Backup should be enabled for Virtual Machines
  - App Service apps should have remote debugging turned off
  - SQL servers should use customer-managed keys (when default=AuditIfNotExists)

### 3. **DeployIfNotExists Effect** (2 policies)
- **Policies:** Guest Configuration extension deployment
- **Recommendation:** Use `DeployIfNotExists` as the effect
- **Rationale:** These policies deploy necessary agents/extensions when not present
- **Policies:**
  - Deploy the Linux Guest Configuration extension to enable Guest Configuration assignments on Linux VMs
  - Deploy the Windows Guest Configuration extension to enable Guest Configuration assignments on Windows VMs

### 4. **Modify Effect** (2 policies)
- **Policies:** Identity remediation for Guest Configuration
- **Recommendation:** Use `Modify` as the effect
- **Rationale:** These policies add system-assigned managed identity
- **Policies:**
  - Add system-assigned managed identity to enable Guest Configuration assignments on virtual machines with no identities
  - Add system-assigned managed identity to enable Guest Configuration assignments on VMs with a user-assigned identity

---

## Special Attention Items

### Policies with Default Effect = "Disabled" (13 total)

These policies have Microsoft's default recommendation as "Disabled", meaning they may be:
- Newer policies not yet widely enabled
- Optional compliance checks with higher operational impact
- Policies requiring careful planning before enabling

**Recommendation:** Enable with caution in non-production first, then evaluate for production.

| Policy | Default | Recommended |
|--------|---------|-------------|
| Azure Cosmos DB accounts should use customer-managed keys | Disabled | Audit |
| Azure Machine Learning workspaces should be encrypted | Disabled | Audit |
| Cognitive Services accounts should enable data encryption | Disabled | Audit |
| Key Vault keys should have an expiration date | Disabled | Audit |
| Key Vault secrets should have an expiration date | Disabled | Audit |
| MySQL servers should use customer-managed keys | Disabled | AuditIfNotExists |
| PostgreSQL servers should use customer-managed keys | Disabled | AuditIfNotExists |
| SQL managed instances should use customer-managed keys | Disabled | Audit |
| Storage accounts should restrict network access | Disabled | Audit |
| Subnets should be associated with a Network Security Group | Disabled | AuditIfNotExists |

### Policies with Parameters (92 policies)
- Marked as `parameter:` in allowedEffects
- Support dynamic effect assignment via policy parameters
- Recommendation: Use recommended effect for both prod and nonprod, then fine-tune via parameters if needed

### Policies with Overrides (25 policies)
- Marked as `override:` in allowedEffects  
- Support effect override at assignment time
- Recommendation: Use recommended effect, can be overridden in specific policy assignments

---

## Implementation Recommendations

### For Production Environment (prodEffect)
1. **Audit/AuditIfNotExists (103 policies):** Monitor compliance without blocking
2. **Audit (10 policies):** Monitor configuration without enforcing
3. **DeployIfNotExists (2 policies):** Automatically deploy required extensions
4. **Modify (2 policies):** Auto-remediate missing identity configurations

### For Non-Production Environment (nonprodEffect)
**Option 1 - Match Production:** Use same effect as production for consistency
- Pros: Validates policies before production
- Cons: May generate audit findings in non-prod

**Option 2 - Conservative:** Use "Disabled" to test gradually
- Pros: Minimal disruption during testing
- Cons: Won't catch actual compliance issues

**Recommended:** Use Option 1 (match production) for most policies, use Option 2 for the 13 "Disabled" default policies that need careful planning.

---

## Usage Instructions

### Option 1: Manual Review
1. Review the full recommendations in `nist-800-53-recommendations.csv`
2. Update `nist-800-53-parameters.csv` manually in Excel or your preferred tool
3. Verify changes before committing

### Option 2: Automated Update (Recommended)
```bash
# Create backup and update with recommendations
python3 update-nist-effects.py \
  Definitions/policyAssignments/nist-800-53-parameters.csv \
  --backup \
  --output Definitions/policyAssignments/nist-800-53-parameters.updated.csv \
  --prod same \
  --nonprod same
```

### Option 3: Custom Strategy
```bash
# Production: recommended effect
# Non-production: Disabled (conservative approach)
python3 update-nist-effects.py \
  Definitions/policyAssignments/nist-800-53-parameters.csv \
  --backup \
  --prod same \
  --nonprod disabled
```

---

## Files Provided

1. **nist-800-53-recommendations.csv** - Full table with all 117 policies and recommendations
2. **update-nist-effects.py** - Automated update script
3. **NIST-800-53-ANALYSIS.md** - This analysis document

---

## Summary Statistics

| Metric | Count |
|--------|-------|
| **Total Empty Policies** | 117 |
| Audit Effect | 10 |
| AuditIfNotExists Effect | 103 |
| DeployIfNotExists Effect | 2 |
| Modify Effect | 2 |
| With Parameters | 92 |
| With Overrides | 25 |
| Default = Disabled | 13 |

---

## Next Steps

1. **Review** the recommendations in the CSV file
2. **Test** in non-production environment
3. **Apply** recommendations using the automated script or manual updates
4. **Validate** that all policies now have prodEffect and nonprodEffect values
5. **Commit** changes to version control
6. **Deploy** to policy assignment stage

---

## Questions or Issues?

- Check `nist-800-53-recommendations.csv` for specific policy details
- Review the allowed effects for each policy to understand constraints
- Consider using the conservative approach for policies marked "Disabled" by default
