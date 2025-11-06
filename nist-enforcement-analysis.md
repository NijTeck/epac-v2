# NIST 800-53 EPAC Enforcement Mode Analysis

## Executive Summary

The EPAC codebase is **currently in Audit-only mode** with all NIST 800-53 policies set to report on non-compliance rather than enforce it. Transitioning to enforcement mode requires **significant configuration changes** plus infrastructure setup for managed identities and role assignments.

---

## Current Effect Configuration

### Policy Distribution by Effect Type

**Total Policies in NIST 800-53 Suite: 238 policies**

| Effect Category | Count | Percentage | Status |
|---|---|---|---|
| **Audit (Current Default)** | 87 | 36.6% | ✅ Currently deployed |
| **No Effect Set (Empty)** | 117 | 49.2% | ⚠️ Requires configuration |
| **DeployIfNotExists Capable** | 2 | 0.8% | 🔧 Auto-remediation |
| **Modify Capable** | 2 | 0.8% | 🔧 Auto-remediation |
| **Deny Capable** | 85 | 35.7% | ⛔ Enforcement blocking |

### Key Findings

**Audit vs. Enforcement Breakdown:**
- **Audit Mode: 36.6%** (87 policies) - Currently monitoring non-compliance
- **Enforcement Capable: 35.7%** (85 policies) - Could enforce compliance via "Deny" effect
- **Auto-Remediation Capable: 1.6%** (4 policies) - Could automatically fix compliance

**Important:** 49.2% of policies have empty `prodEffect` values, meaning they're not configured at all and will not be deployed unless explicitly set.

---

## What's Missing for Enforcement Mode

### 1. Effect Configuration (HIGH PRIORITY)

**Current State:**
- 87 policies set to "Audit" effect in `prodEffect` column
- 117 policies with empty `prodEffect` values
- 0 policies set to enforcement effects like "Deny", "DeployIfNotExists", or "Modify"

**What's Needed:**
```csv
# In nist-800-53-parameters.csv - Examples of needed changes:

# Change from Audit to Deny for enforcement
"Policy ID","prodEffect"
"ef619a2c-cc4d-4d03-b2ba-8c94a834d85b","Deny"  # Instead of "Audit"

# Deploy diagnostic settings automatically
"Policy ID","prodEffect"
"Deploy-Diagnostics-ResourceId","DeployIfNotExists"

# Add managed identity automatically
"Policy ID","prodEffect"
"Add-ManagedIdentity-Policy","Modify"
```

**Current File Location:**
- `/home/user/epac-v2/Definitions/policyAssignments/nist-800-53-parameters.csv`

### 2. Managed Identity Configuration (CRITICAL FOR REMEDIATION)

**Current State:**
- ✅ `managedIdentityLocation` is configured in `global-settings.jsonc` (set to "eastus")
- ❌ No managed identity location specified in `nist-800-53-assignments.jsonc`
- ❌ No identity requirements defined for policies needing remediation

**What's Needed:**

**A. For assignments file (`nist-800-53-assignments.jsonc`):**
```jsonc
{
    "nodeName": "/",
    "scope": { ... },
    "parameterFile": "nist-800-53-parameters.csv",
    "parameterSelector": "default",
    "definitionEntryList": [
        {
            "policySetId": "...",
            "assignment": {
                "name": "nist-800-53-r5",
                "displayName": "NIST SP 800-53 Rev. 5 Compliance",
                "description": "...",
                // ADD THIS SECTION:
                "identity": {
                    "type": "SystemAssigned"
                }
            }
        }
    ]
}
```

**B. For DeployIfNotExists and Modify policies:**
- EPAC will automatically create system-assigned managed identities
- Requires service principal to have:
  - **Resource Policy Contributor** role (to create identities)
  - **RBAC Administrator** role (to assign roles to identities)

### 3. Role Assignments for Managed Identities (CRITICAL FOR REMEDIATION)

**Current State:**
- ✅ `assign-roles.sh` and `assign-remaining-roles.ps1` scripts exist
- ✅ Service principal role assignments are configured for EPAC deployment
- ❌ **No role assignments configured for policy managed identities**

**What's Needed:**

The managed identity created by DeployIfNotExists/Modify policies needs permissions. For example:

```powershell
# After policy deployment, assign roles to managed identity principal:

# For diagnostic settings deployment
$managedIdentityId = "00000000-0000-0000-0000-000000000000"  # Get from deployed identity
$scope = "/subscriptions/..."

# Example: Give read/write permissions for Log Analytics
New-AzRoleAssignment `
    -ObjectId $managedIdentityId `
    -RoleDefinitionName "Log Analytics Contributor" `
    -Scope $scope
```

**Critical Note from code review:**
The `DEPLOYMENT.md` mentions: *"2. Wait 5-10 minutes for managed identity propagation"* and *"2. Verify managed identity has required permissions"*

This indicates managed identity creation is automatic but permission assignment is MANUAL and timing-dependent.

### 4. Service Principal Permissions (ALREADY CONFIGURED)

**Current State:** ✅ **COMPLETE**

Service principals in `assign-roles.sh` have proper roles:
- `tenant-policy` has **Resource Policy Contributor** + Reader
- `tenant-roles` has **RBAC Administrator** + Reader
- `epac-dev-owner` has all three roles

These are sufficient for deploying remediation policies.

---

## Policies Requiring Special Configuration

### DeployIfNotExists Policies (2 total)
These automatically deploy resources to remediate non-compliance:

1. **"Deploy the Linux Guest Configuration extension to enable Guest Configuration assignments on Linux VMs"**
   - Current effect: (empty)
   - Needed effect: `DeployIfNotExists`
   - Requires: Managed identity with permissions to deploy VM extensions

2. **"Deploy the Windows Guest Configuration extension to enable Guest Configuration assignments on Windows VMs"**
   - Current effect: (empty)
   - Needed effect: `DeployIfNotExists`
   - Requires: Managed identity with permissions to deploy VM extensions

### Modify Policies (2 total)
These automatically modify resources to meet compliance:

1. **"Add system-assigned managed identity to enable Guest Configuration assignments on virtual machines with no identities"**
   - Current effect: (empty)
   - Needed effect: `Modify`
   - Requires: Managed identity with permissions to modify VM properties

2. **"Add system-assigned managed identity to enable Guest Configuration assignments on VMs with a user-assigned identity"**
   - Current effect: (empty)
   - Needed effect: `Modify`
   - Requires: Managed identity with permissions to modify VM properties

### Deny/Blocking Policies (85 capable)
Example policies that can switch from Audit to Deny:

- "API Management services should use a virtual network"
- "Azure API for FHIR should use private link"
- "App Configuration should use private link"
- And 82 more...

---

## Potential Breaking Changes & Risks

### 🔴 CRITICAL RISKS

1. **Resource Deployment Blocking**
   - Switching policies to "Deny" effect will **immediately block** creation/modification of non-compliant resources
   - **Risk Level**: High
   - **Impact**: Could break deployment pipelines, CI/CD, infrastructure provisioning
   - **Example**: If you deny storage without encryption, no one can create storage accounts unless they're encrypted
   - **Mitigation**: 
     - Start with 1-2 low-impact policies in non-production
     - Keep audit mode during 30-60 day evaluation period
     - Have rollback plan ready (revert to Audit, redeploy)

2. **Managed Identity Permission Gaps**
   - If managed identity lacks required permissions, remediation will **silently fail**
   - **Risk Level**: High  
   - **Impact**: Policies deployed but not enforced; false sense of compliance
   - **Example**: Modify policies won't add managed identity to VMs if identity lacks VM permissions
   - **Mitigation**: Test with single VM first, check audit logs for "effect not applied" messages

3. **Role Assignment Timing Issues**
   - EPAC creates managed identity with policy, but role assignment takes 5-10 minutes to propagate
   - **Risk Level**: Medium
   - **Impact**: First 5-10 minutes after deployment, remediation tasks won't work
   - **Mitigation**: Don't trigger remediation tasks immediately after deployment; wait 10+ minutes

4. **DeployIfNotExists Infinite Loops**
   - If policy definition has a bug, it could try to deploy/modify repeatedly
   - **Risk Level**: Medium
   - **Impact**: Cost overruns, resource churn
   - **Mitigation**: Test policies thoroughly; monitor remediation task logs

### 🟡 MEDIUM RISKS

5. **Guest Configuration Extension Deployment**
   - Guest Configuration requires Log Analytics agent + extension
   - **Risk Level**: Medium
   - **Impact**: Won't work on locked-down VMs or those without outbound internet
   - **Mitigation**: Verify network connectivity; test on pilot VMs first

6. **Policy Parameter Misalignment**
   - 117 empty `prodEffect` values could cause unexpected behavior
   - **Risk Level**: Medium
   - **Impact**: Policies might not deploy or behave differently than intended
   - **Mitigation**: Audit all 117 empty fields; intentionally set or disable

7. **Compliance Scanning Lag**
   - Takes 30-60 minutes for initial compliance data after effect changes
   - **Risk Level**: Low
   - **Impact**: False reports of "now compliant"; hard to verify enforcement working
   - **Mitigation**: Plan for 1+ hour validation window after changes

### 🟢 LOW RISKS

8. **Service Principal Token Expiration**
   - If OIDC federated credentials misconfigured, deployments fail
   - **Risk Level**: Low (script handles this)
   - **Mitigation**: Already handled by OIDC/federated credentials in place

---

## Step-by-Step Transition Plan

### Phase 0: Pre-Implementation (Current State)
```
Status: ✅ COMPLETE
- Policies deployed in Audit mode
- Service principal roles assigned
- GitHub Actions workflows functional
- Managed identity location configured
```

### Phase 1: Configuration (1-2 weeks)
```
Required Actions:
1. [ ] Audit all 117 empty prodEffect values
   - Determine if intentional or requires configuration
   - Set to "Disable" if not needed, or specify desired effect
   
2. [ ] Identify enforcement priorities
   - Which policies should block resources? (Deny)
   - Which should auto-remediate? (DeployIfNotExists/Modify)
   - Which should stay in audit? (Audit)
   
3. [ ] Update nist-800-53-parameters.csv
   - Change 87 "Audit" policies to target effect
   - Fill in 117 empty prodEffect values
   - Set empty nonprodEffect for non-production environment
   
4. [ ] Update nist-800-53-assignments.jsonc
   - Add identity configuration (if remediation needed)
   - Consider enforcementMode: "DoNotEnforce" for initial rollout
   
5. [ ] Create remediation role assignment process
   - Document which managed identity needs which role
   - Create assignment script for post-deployment
```

### Phase 2: Testing (2-4 weeks)
```
In Development/Non-Prod Subscription:
1. [ ] Deploy with 5 low-risk Deny policies
   - Monitor: Resource creation failures
   - Verify: Non-compliant resources blocked
   - Validate: Existing compliant resources unaffected
   
2. [ ] Deploy DeployIfNotExists policies (2 policies)
   - Monitor: Guest config extensions deployed
   - Verify: Managed identity created
   - Validate: Remediation tasks execute
   
3. [ ] Deploy Modify policies (2 policies)
   - Monitor: VMs modified with managed identity
   - Verify: Policies report compliance improvement
   
4. [ ] Test rollback
   - Change effects back to Audit
   - Redeploy and verify old behavior restored
```

### Phase 3: Staged Production Rollout (2-4 weeks)
```
Week 1: Core Security Policies
- Deploy 10-15 critical Deny policies
- Monitor for 1 week
- Adjust exemptions as needed

Week 2: Remediation Policies
- Enable DeployIfNotExists/Modify policies
- Create remediation tasks
- Monitor deployment/modification actions

Week 3-4: Full Suite
- Enable remaining policies incrementally
- Weekly status reviews
- Document any exemptions/exceptions
```

### Phase 4: Steady State (Ongoing)
```
1. Monitor compliance state
2. Review and approve remediation tasks weekly
3. Adjust enforcement rules based on business needs
4. Quarterly security posture assessment
```

---

## Configuration Change Examples

### Example 1: Change Single Policy from Audit to Deny

```csv
# BEFORE (nist-800-53-parameters.csv)
"name","policyType","displayName","prodEffect","nonprodEffect"
"ef619a2c-cc4d-4d03-b2ba-8c94a834d85b","BuiltIn","API Management services should use a virtual network","Audit","Audit"

# AFTER
"name","policyType","displayName","prodEffect","nonprodEffect"
"ef619a2c-cc4d-4d03-b2ba-8c94a834d85b","BuiltIn","API Management services should use a virtual network","Deny","Audit"
```

### Example 2: Add Identity to Assignment for Remediation

```jsonc
// BEFORE (nist-800-53-assignments.jsonc)
{
    "assignment": {
        "name": "nist-800-53-r5",
        "displayName": "NIST SP 800-53 Rev. 5 Compliance",
        "description": "..."
    }
}

// AFTER
{
    "assignment": {
        "name": "nist-800-53-r5",
        "displayName": "NIST SP 800-53 Rev. 5 Compliance",
        "description": "...",
        "identity": {
            "type": "SystemAssigned"
        }
    }
}
```

### Example 3: Configure Non-Production to Stay in Audit

```csv
# For non-production, keep Audit effect while prod uses Deny
"name","displayName","prodEffect","nonprodEffect"
"ef619a2c-cc4d-4d03-b2ba-8c94a834d85b","API Management services should use a virtual network","Deny","Audit"
```

---

## Validation Checklist

### Before Deploying Enforcement Mode

- [ ] All 117 empty `prodEffect` values reviewed and intentionally configured
- [ ] Deny policies list reviewed for business impact
- [ ] Remediation policies tested in non-prod first
- [ ] Service principal roles verified at tenant root group
- [ ] Managed identity location correct for your region
- [ ] Rollback plan documented (how to revert to Audit)
- [ ] Stakeholders notified of resource creation blocks
- [ ] Compliance scanning baseline established
- [ ] Monitoring/alerting configured for policy violations
- [ ] Exception/exemption process defined

### After Initial Enforcement Deployment

- [ ] Wait 30-60 minutes for compliance scan completion
- [ ] Verify no unexpected resource blocking
- [ ] Check managed identity created for remediation policies
- [ ] Confirm remediation tasks running successfully
- [ ] Review policy compliance state in Azure Portal
- [ ] Validate audit logs for policy denials
- [ ] Confirm no false positive exemptions needed

---

## File Locations & Key Changes

| Component | Location | Change Required |
|---|---|---|
| Policy Effects | `/Definitions/policyAssignments/nist-800-53-parameters.csv` | ⚠️ Update prodEffect & nonprodEffect columns |
| Assignment Config | `/Definitions/policyAssignments/nist-800-53-assignments.jsonc` | ⚠️ Add identity configuration |
| Global Settings | `/Definitions/global-settings.jsonc` | ✅ Already configured (managedIdentityLocation) |
| Service Principals | `/assign-roles.sh`, `/assign-remaining-roles.ps1` | ✅ Already configured |
| Remediation Script | `/AUTOMATED_REMEDIATION_STRATEGY.md` | 📖 Reference guide present |

---

## Summary Table: Enforcement Readiness

| Category | Status | Action Required | Priority |
|---|---|---|---|
| **Effect Configuration** | ❌ NOT READY | Update CSV with prodEffect values | 🔴 CRITICAL |
| **Managed Identity Setup** | ⚠️ PARTIAL | Add identity to assignment file | 🔴 CRITICAL |
| **Service Principal Roles** | ✅ READY | None - already configured | ✅ |
| **Role Assignments for ManagedIdentity** | ❌ NOT READY | Create post-deployment process | 🔴 CRITICAL |
| **Remediation Policies** | ⚠️ PARTIAL | Configure 4 policies (DeployIfNotExists/Modify) | 🟡 HIGH |
| **Audit Policies** | ✅ READY | Can switch to Deny (85 capable) | 🟢 LOW |
| **Testing Framework** | ❌ NOT READY | Design test plan for enforcement | 🟡 HIGH |
| **Rollback Procedure** | ❌ NOT READY | Document revert steps | 🟡 HIGH |

---

## Estimated Timeline

| Phase | Duration | Risk | Recommendation |
|---|---|---|---|
| Configuration | 1-2 weeks | Low | Start immediately |
| Dev Testing | 2-4 weeks | Medium | Test 5 policies first |
| Prod Staging | 1 week | High | Single subscription pilot |
| Production Rollout | 2-4 weeks | High | Incremental (week-by-week) |
| **Total** | **6-11 weeks** | - | Plan accordingly |

