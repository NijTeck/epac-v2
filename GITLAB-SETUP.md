# GitLab CI/CD Setup for EPAC NIST 800-53 Deployment

This guide provides complete instructions for setting up GitLab CI/CD to deploy NIST 800-53 policies to Azure using Enterprise Policy as Code (EPAC).

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Azure Configuration](#azure-configuration)
3. [GitLab Configuration](#gitlab-configuration)
4. [Testing the Pipeline](#testing-the-pipeline)
5. [Troubleshooting](#troubleshooting)

---

## Prerequisites

- Azure subscription with appropriate permissions
- GitLab repository (GitLab.com or self-hosted GitLab 15.7+)
- Azure CLI installed locally for setup
- PowerShell 7+ installed locally

---

## Azure Configuration

### Step 1: Create Azure AD Application (Service Principal)

```bash
# Login to Azure
az login

# Set variables
AZURE_TENANT_ID=$(az account show --query tenantId -o tsv)
AZURE_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
APP_NAME="epac-gitlab-sp"

# Create Azure AD application
az ad app create --display-name "$APP_NAME"

# Get the Application ID
AZURE_CLIENT_ID=$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv)

echo "AZURE_TENANT_ID: $AZURE_TENANT_ID"
echo "AZURE_CLIENT_ID: $AZURE_CLIENT_ID"
echo "AZURE_SUBSCRIPTION_ID: $AZURE_SUBSCRIPTION_ID"
```

### Step 2: Create Service Principal and Assign Permissions

```bash
# Create service principal
az ad sp create --id $AZURE_CLIENT_ID

# Get Service Principal Object ID
SP_OBJECT_ID=$(az ad sp show --id $AZURE_CLIENT_ID --query id -o tsv)

# Assign required roles at Management Group scope
# Replace 'e1f3e196-aa55-4709-9c55-0e334c0b444f' with your Management Group ID
MANAGEMENT_GROUP_ID="e1f3e196-aa55-4709-9c55-0e334c0b444f"

# Assign roles
az role assignment create \
  --assignee $AZURE_CLIENT_ID \
  --role "Resource Policy Contributor" \
  --scope "/providers/Microsoft.Management/managementGroups/$MANAGEMENT_GROUP_ID"

az role assignment create \
  --assignee $AZURE_CLIENT_ID \
  --role "User Access Administrator" \
  --scope "/providers/Microsoft.Management/managementGroups/$MANAGEMENT_GROUP_ID"

az role assignment create \
  --assignee $AZURE_CLIENT_ID \
  --role "Security Admin" \
  --scope "/providers/Microsoft.Management/managementGroups/$MANAGEMENT_GROUP_ID"
```

### Step 3: Configure Workload Identity Federation (OIDC)

This allows GitLab to authenticate to Azure without using secrets/passwords.

```bash
# Get your GitLab project path (e.g., "mygroup/myproject")
GITLAB_PROJECT_PATH="your-gitlab-group/your-project-name"

# For GitLab.com
GITLAB_URL="https://gitlab.com"

# For self-hosted GitLab
# GITLAB_URL="https://gitlab.yourdomain.com"

# Create federated credential for main branch
az ad app federated-credential create \
  --id $AZURE_CLIENT_ID \
  --parameters '{
    "name": "gitlab-main-branch",
    "issuer": "'$GITLAB_URL'",
    "subject": "project_path:'$GITLAB_PROJECT_PATH':ref_type:branch:ref:main",
    "description": "GitLab main branch deployment",
    "audiences": [
      "'$GITLAB_URL'"
    ]
  }'

# Create federated credential for all branches (optional, for testing)
az ad app federated-credential create \
  --id $AZURE_CLIENT_ID \
  --parameters '{
    "name": "gitlab-all-branches",
    "issuer": "'$GITLAB_URL'",
    "subject": "project_path:'$GITLAB_PROJECT_PATH':ref_type:branch:ref:*",
    "description": "GitLab all branches",
    "audiences": [
      "'$GITLAB_URL'"
    ]
  }'

# Create federated credential for merge requests
az ad app federated-credential create \
  --id $AZURE_CLIENT_ID \
  --parameters '{
    "name": "gitlab-merge-requests",
    "issuer": "'$GITLAB_URL'",
    "subject": "project_path:'$GITLAB_PROJECT_PATH':ref_type:merge_request_iid:*",
    "description": "GitLab merge requests",
    "audiences": [
      "'$GITLAB_URL'"
    ]
  }'
```

### Step 4: Verify Federated Credentials

```bash
# List federated credentials
az ad app federated-credential list --id $AZURE_CLIENT_ID
```

You should see three federated credentials:
- `gitlab-main-branch` - For main branch deployments
- `gitlab-all-branches` - For testing on feature branches
- `gitlab-merge-requests` - For merge request validations

---

## GitLab Configuration

### Step 1: Add CI/CD Variables

Navigate to your GitLab project: **Settings > CI/CD > Variables**

Add the following variables:

| Variable Name | Value | Protected | Masked | Description |
|--------------|-------|-----------|--------|-------------|
| `AZURE_TENANT_ID` | `<your-tenant-id>` | ✓ | ✓ | Azure AD Tenant ID |
| `AZURE_CLIENT_ID` | `<your-client-id>` | ✓ | ✓ | Service Principal Application ID |
| `AZURE_SUBSCRIPTION_ID` | `<your-subscription-id>` | ✓ | ✓ | Azure Subscription ID |
| `MANAGEMENT_GROUP_ID` | `e1f3e196-aa55-4709-9c55-0e334c0b444f` | ✓ | - | Management Group ID for deployment |

**Important Settings:**
- **Protected**: Check this box for all variables - they'll only be available in protected branches (main)
- **Masked**: Check this box for sensitive values (IDs) - they'll be hidden in logs
- **Expand variable reference**: Leave unchecked

### Step 2: Create GitLab Environments

Navigate to: **Deployments > Environments**

Create the following environments:

1. **TENANT-PLAN**
   - Name: `TENANT-PLAN`
   - No additional configuration needed

2. **TENANT-DEPLOY-POLICY**
   - Name: `TENANT-DEPLOY-POLICY`
   - Optional: Add deployment approvals if you want manual approval before deployment

3. **TENANT-DEPLOY-ROLES**
   - Name: `TENANT-DEPLOY-ROLES`
   - Optional: Add deployment approvals

### Step 3: Configure Protected Branches

Navigate to: **Settings > Repository > Protected branches**

Ensure `main` branch is protected:
- **Allowed to merge**: Maintainers
- **Allowed to push**: No one (or Maintainers if needed)
- **Allowed to force push**: Unchecked

### Step 4: Enable GitLab CI/CD

The [`.gitlab-ci.yml`](.gitlab-ci.yml) file is already in your repository. GitLab will automatically detect it.

To verify:
1. Go to **CI/CD > Pipelines**
2. You should see pipelines triggered on commits to `main` or merge requests

---

## Pipeline Structure

The GitLab CI/CD pipeline consists of three stages:

### 1. Plan Stage (`plan:tenant`)
- Runs on: Main branch push, Merge Requests
- Actions:
  - Installs EPAC PowerShell module
  - Authenticates to Azure using OIDC
  - Builds deployment plan
  - Uploads plan as artifact

### 2. Deploy Stage
#### `deploy:policy`
- Runs on: Main branch only (after successful plan)
- Actions:
  - Downloads plan artifact
  - Authenticates to Azure
  - Deploys policy assignments

#### `deploy:roles`
- Runs on: Main branch only (after successful policy deployment)
- Actions:
  - Downloads plan artifact
  - Authenticates to Azure
  - Deploys role assignments

### 3. Remediate Stage
#### `remediate:check-compliance`
- Runs on: Main branch only (after successful policy deployment)
- Actions:
  - Checks compliance state
  - Counts non-compliant resources

#### `remediate:create-tasks`
- Runs on: Main branch only (if non-compliant resources found)
- Actions:
  - Creates remediation tasks for NIST 800-53 and MCSB policies
  - Lists remediation task status

---

## Testing the Pipeline

### Test 1: Merge Request (Plan Only)

```bash
# Create a test branch
git checkout -b test-pipeline

# Make a small change to trigger pipeline
echo "# Test comment" >> Definitions/policyAssignments/README.md

# Commit and push
git add .
git commit -m "test: trigger pipeline"
git push origin test-pipeline

# Create merge request in GitLab UI
```

**Expected Result:**
- Pipeline runs `plan:tenant` job
- Deployment jobs are skipped (not on main branch)
- You can review the plan in job logs

### Test 2: Deploy to Main Branch

```bash
# Merge your test MR or push directly to main
git checkout main
git pull
git merge test-pipeline
git push origin main
```

**Expected Result:**
- Pipeline runs all stages: plan → deploy → remediate
- Policies are deployed to Azure
- Remediation tasks are created if needed

### Test 3: Manual Pipeline Run

In GitLab UI:
1. Go to **CI/CD > Pipelines**
2. Click **Run Pipeline**
3. Select branch: `main`
4. Click **Run Pipeline**

---

## Troubleshooting

### Issue: Authentication Failed

**Error:**
```
AADSTS70021: No matching federated identity record found for presented assertion
```

**Solution:**
1. Verify federated credentials are created:
   ```bash
   az ad app federated-credential list --id $AZURE_CLIENT_ID
   ```

2. Check the `subject` claim matches your GitLab project path:
   ```
   subject: "project_path:your-group/your-project:ref_type:branch:ref:main"
   ```

3. For GitLab.com, issuer should be: `https://gitlab.com`
4. For self-hosted, issuer should match your GitLab URL

### Issue: Permission Denied

**Error:**
```
Authorization failed for writing resource
```

**Solution:**
1. Verify service principal has required roles:
   ```bash
   az role assignment list --assignee $AZURE_CLIENT_ID --scope "/providers/Microsoft.Management/managementGroups/$MANAGEMENT_GROUP_ID"
   ```

2. Required roles:
   - Resource Policy Contributor
   - User Access Administrator
   - Security Admin

### Issue: Pipeline Not Triggering

**Solution:**
1. Check [`.gitlab-ci.yml`](.gitlab-ci.yml) is in repository root
2. Verify changes are in `Definitions/**` path
3. Check pipeline rules in `.gitlab-ci.yml`

### Issue: Variables Not Available

**Solution:**
1. Verify variables are set in **Settings > CI/CD > Variables**
2. Ensure variables are marked as **Protected** if running on protected branch
3. Check variable names match exactly (case-sensitive)

### Issue: EPAC Module Installation Fails

**Solution:**
1. The pipeline uses `mcr.microsoft.com/azure-powershell:latest` image
2. Verify internet access from GitLab runner
3. Check PowerShell Gallery is accessible

---

## Comparison: GitHub vs GitLab

| Feature | GitHub Actions | GitLab CI/CD |
|---------|---------------|--------------|
| **Workflow File** | `.github/workflows/*.yml` | `.gitlab-ci.yml` |
| **Authentication** | `azure/login@v2` action | Azure CLI with OIDC |
| **Artifacts** | `actions/upload-artifact@v4` | `artifacts:` keyword |
| **Environments** | Repository environments | Project environments |
| **Secrets** | Repository secrets | CI/CD variables |
| **Stages** | `jobs` | `stages` + `jobs` |
| **Dependencies** | `needs:` | `needs:` + `dependencies:` |

---

## Additional Configuration Options

### Option 1: Add Manual Approval Gates

Edit environments in GitLab:
1. Go to **Settings > CI/CD > Protected Environments**
2. Add `TENANT-DEPLOY-POLICY` as protected environment
3. Set **Allowed to deploy**: Specific users/groups
4. Deployment will wait for manual approval

### Option 2: Add Notifications

Add to `.gitlab-ci.yml`:
```yaml
after_script:
  - |
    if [ "$CI_JOB_STATUS" == "failed" ]; then
      # Send notification (email, Slack, Teams, etc.)
      echo "Deployment failed!"
    fi
```

### Option 3: Schedule Regular Compliance Checks

In GitLab:
1. Go to **CI/CD > Schedules**
2. Click **New schedule**
3. Set description: "Weekly Compliance Check"
4. Set interval: `0 0 * * 0` (Every Sunday at midnight)
5. Target branch: `main`
6. Variable: `SKIP_DEPLOY=true` (if you only want to check compliance)

---

## Security Best Practices

1. **Use OIDC Instead of Secrets**
   - Workload Identity Federation (OIDC) eliminates the need for long-lived secrets
   - Tokens are short-lived and scoped to specific operations

2. **Protect Sensitive Variables**
   - Always mark Azure credentials as **Protected** and **Masked**
   - Use protected branches for production deployments

3. **Limit Service Principal Permissions**
   - Follow principle of least privilege
   - Assign roles only at required scope (Management Group level)

4. **Regular Audits**
   - Review pipeline execution logs regularly
   - Monitor Azure Activity Logs for policy changes
   - Review compliance reports weekly

5. **Branch Protection**
   - Require merge requests for main branch
   - Require approvals before merge
   - Run CI/CD checks on all merge requests

---

## Support and Documentation

- **EPAC Documentation**: https://github.com/Azure/enterprise-azure-policy-as-code
- **GitLab CI/CD Docs**: https://docs.gitlab.com/ee/ci/
- **Azure OIDC with GitLab**: https://docs.gitlab.com/ee/ci/cloud_services/azure/
- **NIST 800-53**: https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final

---

## Quick Reference Commands

### View Pipeline Status
```bash
# Using GitLab CLI (if installed)
glab ci status

# Using GitLab API
curl --header "PRIVATE-TOKEN: <your-token>" \
  "https://gitlab.com/api/v4/projects/<project-id>/pipelines"
```

### Manually Trigger Pipeline
```bash
# Using GitLab CLI
glab ci run

# Using GitLab API
curl --request POST \
  --header "PRIVATE-TOKEN: <your-token>" \
  "https://gitlab.com/api/v4/projects/<project-id>/pipeline?ref=main"
```

### Check Azure Policy Compliance
```bash
az policy state list \
  --management-group "e1f3e196-aa55-4709-9c55-0e334c0b444f" \
  --filter "complianceState eq 'NonCompliant'" \
  --query "length(@)"
```

---

## Next Steps

1. Complete Azure configuration (Steps 1-4)
2. Configure GitLab CI/CD variables
3. Create GitLab environments
4. Test with merge request
5. Deploy to main branch
6. Monitor compliance and remediation

For questions or issues, contact your Azure administrator or DevOps team.
