# GitLab CI/CD Quick Start Checklist

Use this checklist to quickly set up GitLab CI/CD for EPAC NIST 800-53 deployment.

## Prerequisites Checklist

- [ ] Azure subscription with appropriate permissions
- [ ] GitLab account (GitLab.com or self-hosted)
- [ ] Azure CLI installed
- [ ] Management Group ID: `11111111111111111111111111111111111111111`

---

## Azure Setup (30 minutes)

### Step 1: Create Service Principal

```bash
# Login and set variables
az login
AZURE_TENANT_ID=$(az account show --query tenantId -o tsv)
AZURE_CLIENT_ID=$(az ad app create --display-name "epac-gitlab-sp" --query appId -o tsv)
az ad sp create --id $AZURE_CLIENT_ID

# Save these values - you'll need them for GitLab
echo "AZURE_TENANT_ID: $AZURE_TENANT_ID"
echo "AZURE_CLIENT_ID: $AZURE_CLIENT_ID"
```

- [ ] Service principal created
- [ ] Values saved securely

### Step 2: Assign Permissions

```bash
MANAGEMENT_GROUP_ID="11111111111111111111111111111111111111111"

az role assignment create --assignee $AZURE_CLIENT_ID --role "Resource Policy Contributor" --scope "/providers/Microsoft.Management/managementGroups/$MANAGEMENT_GROUP_ID"
az role assignment create --assignee $AZURE_CLIENT_ID --role "User Access Administrator" --scope "/providers/Microsoft.Management/managementGroups/$MANAGEMENT_GROUP_ID"
az role assignment create --assignee $AZURE_CLIENT_ID --role "Security Admin" --scope "/providers/Microsoft.Management/managementGroups/$MANAGEMENT_GROUP_ID"
```

- [ ] Resource Policy Contributor assigned
- [ ] User Access Administrator assigned
- [ ] Security Admin assigned

### Step 3: Configure OIDC

```bash
# Set your GitLab project path
GITLAB_PROJECT_PATH="your-group/your-project"
GITLAB_URL="https://gitlab.com"

# Create federated credentials
az ad app federated-credential create --id $AZURE_CLIENT_ID --parameters '{
  "name": "gitlab-main-branch",
  "issuer": "'$GITLAB_URL'",
  "subject": "project_path:'$GITLAB_PROJECT_PATH':ref_type:branch:ref:main",
  "audiences": ["'$GITLAB_URL'"]
}'

az ad app federated-credential create --id $AZURE_CLIENT_ID --parameters '{
  "name": "gitlab-merge-requests",
  "issuer": "'$GITLAB_URL'",
  "subject": "project_path:'$GITLAB_PROJECT_PATH':ref_type:merge_request_iid:*",
  "audiences": ["'$GITLAB_URL'"]
}'
```

- [ ] Main branch credential created
- [ ] Merge request credential created
- [ ] Credentials verified with: `az ad app federated-credential list --id $AZURE_CLIENT_ID`

---

## GitLab Setup (15 minutes)

### Step 4: Add CI/CD Variables

Go to: **Settings > CI/CD > Variables**

Add these variables (all **Protected** ✓ and **Masked** ✓):

- [ ] `AZURE_TENANT_ID` = `<from Step 1>`
- [ ] `AZURE_CLIENT_ID` = `<from Step 1>`
- [ ] `AZURE_SUBSCRIPTION_ID` = `<your-subscription-id>`
- [ ] `MANAGEMENT_GROUP_ID` = `11111111111111111111111111111111111111111`

### Step 5: Create Environments

Go to: **Deployments > Environments**

Create these environments:

- [ ] `TENANT-PLAN`
- [ ] `TENANT-DEPLOY-POLICY`
- [ ] `TENANT-DEPLOY-ROLES`

### Step 6: Protect Main Branch

Go to: **Settings > Repository > Protected branches**

- [ ] Main branch protected
- [ ] Allowed to push: **No one** (or Maintainers only)
- [ ] Allowed to merge: **Maintainers**

---

## Testing (15 minutes)

### Step 7: Test with Merge Request

```bash
git checkout -b test-gitlab-pipeline
echo "# Test" >> Definitions/policyAssignments/README.md
git add .
git commit -m "test: verify GitLab pipeline"
git push origin test-gitlab-pipeline
```

- [ ] Create merge request in GitLab
- [ ] Pipeline runs successfully
- [ ] Plan job completes
- [ ] Review plan output in job logs

### Step 8: Deploy to Main

```bash
# After MR approval
git checkout main
git pull
git merge test-gitlab-pipeline
git push origin main
```

- [ ] Pipeline runs all stages
- [ ] Plan stage succeeds
- [ ] Deploy policy stage succeeds
- [ ] Deploy roles stage succeeds (if applicable)
- [ ] Remediation stage runs (if applicable)

### Step 9: Verify in Azure

```bash
az policy assignment list \
  --management-group "11111111111111111111111111111111111111111" \
  --query "[?contains(displayName, 'NIST')].{Name:displayName,ID:id}" \
  -o table
```

- [ ] NIST policy assignments visible in Azure
- [ ] Policies deployed to correct Management Group
- [ ] No errors in Azure Activity Log

---

## Troubleshooting Quick Fixes

### Authentication Failed

```bash
# Verify federated credentials
az ad app federated-credential list --id $AZURE_CLIENT_ID

# Check subject matches: project_path:GROUP/PROJECT:ref_type:branch:ref:main
```

### Permission Denied

```bash
# Verify role assignments
az role assignment list --assignee $AZURE_CLIENT_ID \
  --scope "/providers/Microsoft.Management/managementGroups/$MANAGEMENT_GROUP_ID"
```

### Pipeline Not Running

- Check `.gitlab-ci.yml` is in repository root
- Verify changes are in `Definitions/**` path
- Check **CI/CD > Pipelines** for error messages

### Variables Not Found

- Ensure variables are marked as **Protected**
- Verify variable names match exactly (case-sensitive)
- Check running on protected branch (main)

---

## Success Criteria

Your setup is complete when:

- [x] All Azure roles assigned
- [x] OIDC federated credentials created
- [x] GitLab CI/CD variables configured
- [x] GitLab environments created
- [x] Test merge request pipeline passes
- [x] Main branch deployment succeeds
- [x] Policies visible in Azure Portal

---

## Next Steps

1. **Set up scheduled compliance checks**
   - Go to: **CI/CD > Schedules**
   - Create weekly schedule for compliance reports

2. **Add approval gates** (optional)
   - Go to: **Settings > CI/CD > Protected Environments**
   - Add `TENANT-DEPLOY-POLICY` as protected
   - Require manual approval before deployment

3. **Configure notifications**
   - Set up email/Slack/Teams notifications for failed pipelines
   - Add to `.gitlab-ci.yml` after_script section

4. **Document custom policies**
   - Document any custom policy definitions
   - Add to repository README

5. **Regular maintenance**
   - Review compliance reports weekly
   - Update policy definitions monthly
   - Rotate federated credentials annually (automatic with OIDC)

---

## Support

- Full documentation: [GITLAB-SETUP.md](GITLAB-SETUP.md)
- EPAC docs: https://github.com/Azure/enterprise-azure-policy-as-code
- GitLab CI/CD: https://docs.gitlab.com/ee/ci/
- Azure OIDC: https://docs.gitlab.com/ee/ci/cloud_services/azure/

---

## Estimated Total Time

- Azure setup: 30 minutes
- GitLab configuration: 15 minutes
- Testing: 15 minutes
- **Total: ~60 minutes**

---

## Key Files Created

- [`.gitlab-ci.yml`](.gitlab-ci.yml) - Main pipeline configuration
- [`GITLAB-SETUP.md`](GITLAB-SETUP.md) - Detailed setup documentation
- [`GITLAB-QUICKSTART.md`](GITLAB-QUICKSTART.md) - This checklist

Your GitHub Actions workflows remain unchanged and will continue to work alongside GitLab CI/CD.
