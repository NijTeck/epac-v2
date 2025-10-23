# Complete Deployment Checklist for NIST 800-53 EPAC

## Current Status: NOT READY FOR DEPLOYMENT ❌

This checklist identifies what's missing and what needs to be configured for successful deployment via GitHub Actions.

---

## 🔴 CRITICAL - Must Fix Before Any Deployment

### 1. Azure Configuration - MISSING ❌
These placeholder values **MUST** be replaced with your actual Azure IDs:

#### In `Definitions/global-settings.jsonc`:
- [ ] Replace `<YOUR-TENANT-ID>` with your Azure AD Tenant ID (both environments)
- [ ] Replace `<YOUR-DEV-MG>` with your Dev Management Group ID
- [ ] Replace `<YOUR-PROD-MG>` with your Production Management Group ID
- [ ] Update `managedIdentityLocation` if not using `eastus`

#### In `Definitions/policyAssignments/nist-800-53-assignments.jsonc`:
- [ ] Replace `<YOUR-DEV-PROD-MG>` with your Dev Prod Management Group ID
- [ ] Replace `<YOUR-PROD-MG>` with your Prod Management Group ID
- [ ] Replace `<YOUR-DEV-NONPROD-MG>` with your Dev Nonprod Management Group ID
- [ ] Replace `<YOUR-NONPROD-MG>` with your Nonprod Management Group ID

**To find your values:**
```powershell
# Get Tenant ID
(Get-AzContext).Tenant.Id

# List Management Groups
Get-AzManagementGroup | Select-Object Name, DisplayName
```

---

## 🟡 REQUIRED - Service Principals Setup

### 2. Create Service Principals ❌
You need 4 service principals with federated credentials:

| Service Principal | Environment | Required Roles |
|---|---|---|
| [ ] epac-dev-owner | EPAC-DEV | Reader, Resource Policy Contributor, RBAC Administrator |
| [ ] tenant-plan | TENANT-PLAN | Reader |
| [ ] tenant-policy | TENANT-DEPLOY-POLICY | Reader, Resource Policy Contributor |
| [ ] tenant-roles | TENANT-DEPLOY-ROLES | Reader, RBAC Administrator |

**Quick Setup:**
```powershell
# Run the automated script from SERVICE_PRINCIPALS.md
.\Setup-ServicePrincipals.ps1 `
    -TenantId "YOUR-TENANT-ID" `
    -DevManagementGroupId "YOUR-DEV-MG" `
    -ProdManagementGroupId "YOUR-PROD-MG" `
    -GitHubOrg "YOUR-GITHUB-ORG" `
    -GitHubRepo "enterprise-azure-policy-as-code"
```

---

## 🟡 REQUIRED - GitHub Configuration

### 3. Create GitHub Environments ❌
In your GitHub repository settings, create these 4 environments:

#### [ ] EPAC-DEV Environment
- Protection rules: None
- Secrets:
  - `AZURE_CLIENT_ID`: (from epac-dev-owner service principal)
  - `AZURE_TENANT_ID`: (your tenant ID)

#### [ ] TENANT-PLAN Environment
- Protection rules: None
- Secrets:
  - `AZURE_CLIENT_ID`: (from tenant-plan service principal)
  - `AZURE_TENANT_ID`: (your tenant ID)

#### [ ] TENANT-DEPLOY-POLICY Environment
- Protection rules:
  - ✅ Required reviewers (1-2 people)
  - ✅ Deployment branches: `main` only
- Secrets:
  - `AZURE_CLIENT_ID`: (from tenant-policy service principal)
  - `AZURE_TENANT_ID`: (your tenant ID)

#### [ ] TENANT-DEPLOY-ROLES Environment
- Protection rules:
  - ✅ Required reviewers (1-2 people)
  - ✅ Deployment branches: `main` only
- Secrets:
  - `AZURE_CLIENT_ID`: (from tenant-roles service principal)
  - `AZURE_TENANT_ID`: (your tenant ID)

### 4. Configure Branch Protection ❌
- [ ] Protect `main` branch
- [ ] Require PR reviews before merge
- [ ] Require status checks to pass

---

## 🟢 OPTIONAL - Recommended Configuration

### 5. Azure Management Group Structure
Verify your management group hierarchy:
```
Tenant Root Group
├── Production (YOUR-PROD-MG)
├── Non-Production (YOUR-NONPROD-MG)
└── Development
    ├── Dev-Prod (YOUR-DEV-PROD-MG)
    └── Dev-Nonprod (YOUR-DEV-NONPROD-MG)
```

### 6. Review Policy Parameters
- [ ] Review `Definitions/policyAssignments/nist-800-53-parameters.csv`
- [ ] All policies start with "Audit" effect (safe default)
- [ ] Consider which policies should be "Deny" in production

---

## 📋 Deployment Steps (After Prerequisites Complete)

### First Deployment - Test in Dev:
```bash
# 1. Create feature branch
git checkout -b feature/initial-deployment

# 2. Commit your configuration changes
git add Definitions/
git commit -m "feat: configure Azure environment IDs"
git push origin feature/initial-deployment

# 3. Check GitHub Actions - should auto-deploy to EPAC-DEV
# 4. Verify in Azure Portal - check Dev Management Group
```

### Production Deployment:
```bash
# 1. Create PR to main branch
# 2. Review the deployment plan in PR checks
# 3. Merge PR after approval
# 4. Approve TENANT-DEPLOY-POLICY deployment
# 5. Approve TENANT-DEPLOY-ROLES deployment
# 6. Verify in Azure Portal - check Prod Management Group
```

---

## ⚠️ Common Issues and Solutions

### Issue: "Management group not found"
**Fix:** Ensure management group IDs are correct (not display names)

### Issue: "Insufficient permissions"
**Fix:** Verify service principal role assignments at management group scope

### Issue: "OIDC token validation failed"
**Fix:** Check federated credential configuration matches GitHub environment name

### Issue: "Environment not found"
**Fix:** Ensure GitHub environment names match exactly (case-sensitive)

---

## 🚦 Deployment Readiness Status

| Component | Status | Action Required |
|---|---|---|
| Azure Tenant ID | ❌ Not Configured | Replace `<YOUR-TENANT-ID>` |
| Management Group IDs | ❌ Not Configured | Replace all `<YOUR-*-MG>` placeholders |
| Service Principals | ❌ Not Created | Run setup script or create manually |
| GitHub Environments | ❌ Not Created | Create 4 environments with secrets |
| Branch Protection | ❌ Not Configured | Enable on main branch |
| Workflow Files | ✅ Ready | No action needed |
| Policy Configuration | ✅ Ready | No action needed |

**Overall Status: NOT READY - Complete all ❌ items first**

---

## 📚 Reference Documentation

- `SERVICE_PRINCIPALS.md` - Detailed service principal setup
- `GITHUB_SETUP.md` - Detailed GitHub configuration
- `DEPLOYMENT.md` - Deployment procedures
- `README.md` - Overall documentation

---

## Quick Commands Reference

### Find Your Azure IDs:
```powershell
# Connect to Azure
Connect-AzAccount

# Get Tenant ID
(Get-AzContext).Tenant.Id

# List Management Groups
Get-AzManagementGroup | Format-Table Name, DisplayName

# Get specific management group
Get-AzManagementGroup -GroupId "YOUR-MG-NAME"
```

### Test Service Principal:
```powershell
# Test service principal login
$appId = "YOUR-APP-ID"
$tenantId = "YOUR-TENANT-ID"
Connect-AzAccount -ServicePrincipal -ApplicationId $appId -Tenant $tenantId

# Verify access
Get-AzManagementGroup
```

### Monitor Deployment:
```powershell
# Check policy assignments
Get-AzPolicyAssignment -Scope "/providers/Microsoft.Management/managementGroups/YOUR-MG"

# Check compliance state
Get-AzPolicyState -ManagementGroupName "YOUR-MG" | Where-Object ComplianceState -eq "NonCompliant"
```

---

**Last Updated:** Current deployment readiness assessment
**Next Review:** After completing configuration steps