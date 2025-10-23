# GitHub Repository Setup Guide

This guide walks through configuring your GitHub repository for NIST 800-53 EPAC deployment.

## Prerequisites

- GitHub repository created
- Service principals created with federated credentials (see [SERVICE_PRINCIPALS.md](SERVICE_PRINCIPALS.md))
- Admin access to GitHub repository

## Step 1: Create GitHub Environments

GitHub Environments provide deployment protection rules and secrets management.

### Create Environments

1. Navigate to your repository on GitHub
2. Click **Settings** > **Environments**
3. Click **New environment**
4. Create the following four environments:

#### Environment 1: EPAC-DEV

**Name**: `EPAC-DEV`

**Purpose**: Development environment deployment (no approval needed)

**Protection Rules**:
- ❌ No required reviewers
- ❌ No branch restrictions
- ❌ No wait timer

**Secrets** (click "Add secret"):
- `AZURE_CLIENT_ID`: Application (client) ID of your epac-dev service principal
- `AZURE_TENANT_ID`: Your Azure AD tenant ID

#### Environment 2: TENANT-PLAN

**Name**: `TENANT-PLAN`

**Purpose**: Generate production deployment plan

**Protection Rules**:
- ❌ No required reviewers
- ❌ No branch restrictions
- ❌ No wait timer

**Secrets**:
- `AZURE_CLIENT_ID`: Application (client) ID of your tenant-plan service principal
- `AZURE_TENANT_ID`: Your Azure AD tenant ID

#### Environment 3: TENANT-DEPLOY-POLICY

**Name**: `TENANT-DEPLOY-POLICY`

**Purpose**: Deploy NIST 800-53 policies to production

**Protection Rules**:
- ✅ **Required reviewers**: Add 1-2 approvers
- ✅ **Deployment branches**: Select "Selected branches" and add `main`
- ❌ No wait timer (or add if desired)
- ✅ **Prevent administrators from bypassing**: Enabled

**Secrets**:
- `AZURE_CLIENT_ID`: Application (client) ID of your tenant-policy service principal
- `AZURE_TENANT_ID`: Your Azure AD tenant ID

#### Environment 4: TENANT-DEPLOY-ROLES

**Name**: `TENANT-DEPLOY-ROLES`

**Purpose**: Deploy role assignments for managed identities

**Protection Rules**:
- ✅ **Required reviewers**: Add 1-2 approvers (can be same as TENANT-DEPLOY-POLICY)
- ✅ **Deployment branches**: Select "Selected branches" and add `main`
- ❌ No wait timer (or add if desired)
- ✅ **Prevent administrators from bypassing**: Enabled

**Secrets**:
- `AZURE_CLIENT_ID`: Application (client) ID of your tenant-roles service principal
- `AZURE_TENANT_ID`: Your Azure AD tenant ID

## Step 2: Configure Branch Protection Rules

Protect the `main` branch to ensure all changes go through PR review.

### Enable Branch Protection

1. Navigate to **Settings** > **Branches**
2. Click **Add branch protection rule**
3. Configure:

**Branch name pattern**: `main`

**Protection settings**:
- ✅ **Require a pull request before merging**
  - ✅ Require approvals: 1
  - ✅ Dismiss stale pull request approvals when new commits are pushed
  - ❌ Require review from Code Owners (optional)
- ✅ **Require status checks to pass before merging**
  - ✅ Require branches to be up to date before merging
  - Add status checks: (will appear after first workflow run)
    - `Plan epac-dev`
    - `Deploy epac-dev Policy Changes`
    - `Deploy epac-dev Role Changes`
- ✅ **Require conversation resolution before merging**
- ✅ **Do not allow bypassing the above settings** (recommended)
- ❌ Allow force pushes: Disabled
- ❌ Allow deletions: Disabled

4. Click **Create** or **Save changes**

## Step 3: Verify GitHub Actions Permissions

Ensure GitHub Actions has necessary permissions.

1. Navigate to **Settings** > **Actions** > **General**
2. Scroll to **Workflow permissions**
3. Select:
   - ✅ **Read and write permissions** (for uploading artifacts)
   - ✅ **Allow GitHub Actions to create and approve pull requests** (if using automated PRs)
4. Click **Save**

## Step 4: Configure OIDC Trust Relationship

Verify federated credentials are configured in Azure AD for each service principal.

### For Each Service Principal

1. Navigate to **Azure Portal** > **Azure Active Directory** > **App registrations**
2. Select your service principal
3. Click **Certificates & secrets** > **Federated credentials**
4. Verify credential exists with:
   - **Federated credential scenario**: GitHub Actions deploying Azure resources
   - **Organization**: Your GitHub username or org
   - **Repository**: Your repository name
   - **Entity type**: Environment
   - **Environment name**: Matches GitHub environment name (e.g., `EPAC-DEV`)

If missing, see [SERVICE_PRINCIPALS.md](SERVICE_PRINCIPALS.md) for setup instructions.

## Step 5: Test GitHub Actions

### Test Dev Deployment

1. Create a test branch:
   ```bash
   git checkout -b feature/test-deployment
   ```

2. Make a small change to `Definitions/policyAssignments/nist-800-53-parameters.csv`

3. Commit and push:
   ```bash
   git add .
   git commit -m "test: verify GitHub Actions deployment"
   git push origin feature/test-deployment
   ```

4. Check **Actions** tab in GitHub - should see "EPAC Dev Workflow" running

5. Verify workflow completes successfully

### Test Production Deployment

1. Create PR from feature branch to main

2. Review the PR - should see plan output in workflow logs

3. Merge PR

4. Check **Actions** tab - should see "EPAC Tenant Workflow" running

5. Workflow will pause at TENANT-DEPLOY-POLICY environment
   - Review the deployment plan
   - Click **Review deployments**
   - Select **TENANT-DEPLOY-POLICY**
   - Click **Approve and deploy**

6. Workflow will pause again at TENANT-DEPLOY-ROLES
   - Click **Review deployments**
   - Select **TENANT-DEPLOY-ROLES**
   - Click **Approve and deploy**

7. Verify workflow completes successfully

## Environment Secrets Reference

| Environment | AZURE_CLIENT_ID | AZURE_TENANT_ID | Purpose |
|-------------|-----------------|-----------------|---------|
| EPAC-DEV | epac-dev SPN | Your tenant ID | Dev deployment |
| TENANT-PLAN | tenant-plan SPN | Your tenant ID | Prod plan generation |
| TENANT-DEPLOY-POLICY | tenant-policy SPN | Your tenant ID | Prod policy deployment |
| TENANT-DEPLOY-ROLES | tenant-roles SPN | Your tenant ID | Prod role deployment |

## Troubleshooting

### Issue: "Environment not found" error

**Solution**: Verify environment name matches exactly (case-sensitive):
- Workflow file: `planGitHubEnvironment: EPAC-DEV`
- GitHub environment name: `EPAC-DEV`

### Issue: "OIDC token validation failed"

**Solution**: Verify federated credential configuration:
1. Check organization/repository name matches
2. Check environment name matches
3. Check entity type is "Environment"
4. Verify credential is not expired

### Issue: "Secrets not found"

**Solution**: 
1. Verify secrets are added to the correct environment (not repository secrets)
2. Check secret names are exactly: `AZURE_CLIENT_ID` and `AZURE_TENANT_ID`
3. Verify secret values are correct (no extra spaces)

### Issue: Workflow doesn't trigger

**Solution**:
1. Verify workflow files are in `.github/workflows/` folder
2. Check branch name matches trigger (e.g., `feature/**` for dev workflow)
3. Verify changes are in `Definitions/` folder (path filter)
4. Check GitHub Actions is enabled in repository settings

### Issue: Approval not requested

**Solution**:
1. Verify environment protection rules are configured
2. Check required reviewers are added
3. Verify deployment branch is set to `main`
4. Ensure workflow is running on `main` branch (for tenant workflow)

## Security Best Practices

1. ✅ **Use separate service principals** for each environment
2. ✅ **Enable required reviewers** for production deployments
3. ✅ **Restrict deployment branches** to `main` only
4. ✅ **Enable branch protection** on `main`
5. ✅ **Use OIDC** (federated credentials) instead of client secrets
6. ✅ **Rotate credentials** annually
7. ✅ **Audit deployment logs** regularly
8. ✅ **Limit repository access** to necessary personnel

## Next Steps

After completing GitHub setup:

1. ✅ Test dev deployment with feature branch
2. ✅ Test production deployment with PR to main
3. ✅ Review Azure Policy compliance in portal
4. ✅ Adjust policy effects in CSV as needed
5. ✅ Document your approval process for team

## Additional Resources

- [GitHub Environments Documentation](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)
- [GitHub Branch Protection Documentation](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [Azure Workload Identity Federation](https://learn.microsoft.com/en-us/azure/active-directory/workload-identities/workload-identity-federation)
