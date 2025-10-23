# Design Document

## Overview

This design implements a streamlined Enterprise Policy as Code (EPAC) solution focused **exclusively on NIST 800-53 Rev. 5** compliance framework deployment. The solution provides dual deployment paths: automated CI/CD through GitHub Actions and manual local deployment from a developer workstation. 

**Key Simplification**: Since NIST 800-53 Rev. 5 is a **built-in Azure policy set**, we don't need custom policy definitions or policy set definitions. We only need to:
1. **Assign** the built-in NIST 800-53 policy set to management groups
2. **Configure parameters** for each policy within the set (via CSV)
3. **Deploy** assignments and role assignments for managed identities

This eliminates the need for `policyDefinitions/` and `policySetDefinitions/` folders entirely.

### Key Design Principles

1. **Single Framework Focus**: Only NIST 800-53 Rev. 5 (no Azure Security Benchmark, PCI-DSS, or other frameworks)
2. **Built-in Policy Set**: Leverage Azure's built-in NIST 800-53 policy set (ID: 179d1daa-458f-4e47-8086-2a68d0d6c38f)
3. **Dual Deployment Model**: Support both GitHub Actions automation and local PowerShell script execution
4. **Environment Separation**: Clear distinction between epac-dev and production (tenant) environments
5. **Minimal Configuration**: Only policyAssignments folder required; policyDocumentations and policyExemptions are optional
6. **Parameter-Driven**: CSV-based parameter management for configuring 300+ NIST 800-53 policies

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Developer Workstation                     │
│  ┌────────────────┐         ┌──────────────────────┐       │
│  │  Local Scripts │────────▶│  Azure Cloud         │       │
│  │  (PowerShell)  │         │  - Management Groups │       │
│  └────────────────┘         │  - Policy Resources  │       │
│         │                    │  - Role Assignments  │       │
│         │                    └──────────────────────┘       │
│         ▼                                                    │
│  ┌────────────────┐                                         │
│  │  Git Repository│                                         │
│  │  (Local Clone) │                                         │
│  └────────────────┘                                         │
└──────────┬──────────────────────────────────────────────────┘
           │
           │ Push/PR
           ▼
┌─────────────────────────────────────────────────────────────┐
│                      GitHub Repository                       │
│  ┌────────────────────────────────────────────────────┐    │
│  │              Definitions/                           │    │
│  │  ├── global-settings.jsonc                         │    │
│  │  └── policyAssignments/                            │    │
│  │      ├── nist-800-53-assignments.jsonc             │    │
│  │      └── nist-800-53-parameters.csv                │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │         .github/workflows/                          │    │
│  │  ├── epac-dev-workflow.yml                         │    │
│  │  └── epac-tenant-workflow.yml                      │    │
│  └────────────────────────────────────────────────────┘    │
└──────────┬───────────────────────────────────────────────────┘
           │
           │ GitHub Actions Trigger
           ▼
┌─────────────────────────────────────────────────────────────┐
│                   GitHub Actions Runner                      │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐ │
│  │  Plan Job    │───▶│ Deploy Policy│───▶│ Deploy Roles │ │
│  │  (Build)     │    │  Job         │    │  Job         │ │
│  └──────────────┘    └──────────────┘    └──────────────┘ │
│         │                    │                    │         │
│         └────────────────────┴────────────────────┘         │
│                              │                               │
└──────────────────────────────┼───────────────────────────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │   Azure Cloud        │
                    │  - Management Groups │
                    │  - Policy Resources  │
                    │  - Role Assignments  │
                    └──────────────────────┘
```

### Deployment Flow

#### GitHub Actions Flow
1. Developer creates/modifies policy definitions in feature branch
2. Push triggers plan generation (no deployment)
3. Pull request created with plan review
4. PR merge to main triggers deployment workflow
5. Plan job executes and uploads artifacts
6. Deploy Policy job requires approval, then deploys policies
7. Deploy Roles job requires approval, then deploys role assignments

#### Local Deployment Flow
1. Developer authenticates to Azure (service principal or user)
2. Runs Build-DeploymentPlans.ps1 locally
3. Reviews generated plan files in Output/ folder
4. Runs Deploy-PolicyPlan.ps1 to deploy policies
5. Runs Deploy-RolesPlan.ps1 to deploy role assignments

## Components and Interfaces

### 1. Directory Structure

```
Repository Root/
├── .github/
│   └── workflows/
│       ├── epac-dev-workflow.yml          # Dev environment automation
│       ├── epac-tenant-workflow.yml       # Prod environment automation
│       ├── plan.yml                       # Reusable plan template
│       ├── deploy-policy.yml              # Reusable policy deploy template
│       └── deploy-roles.yml               # Reusable roles deploy template
│
├── Definitions/                            # EPAC reads ONLY from this folder
│   ├── global-settings.jsonc              # REQUIRED: Environment configuration
│   ├── policyAssignments/                 # REQUIRED: NIST 800-53 assignments
│   │   ├── nist-800-53-assignments.jsonc  # Assignment configuration
│   │   └── nist-800-53-parameters.csv     # Policy parameters (NIST 800-53 only)
│   ├── policyDocumentations/              # OPTIONAL: Compliance documentation
│   └── policyExemptions/                  # OPTIONAL: Policy exemptions
│
├── Output/                                 # Auto-generated by EPAC (gitignored)
│   ├── policy-plan.json                   # Generated deployment plan
│   └── roles-plan.json                    # Generated role assignments
│
├── StarterKit/                             # Reference examples (not used by EPAC)
│   └── (keep for reference)
│
└── README.md                               # NIST 800-53 deployment documentation

NOTE: NO policyDefinitions/ or policySetDefinitions/ folders needed
      NIST 800-53 Rev. 5 is a built-in Azure policy set (ID: 179d1daa-458f-4e47-8086-2a68d0d6c38f)
```

### 2. Configuration Files

#### global-settings.jsonc

Defines two PAC environments:

```jsonc
{
  "$schema": "https://raw.githubusercontent.com/Azure/enterprise-azure-policy-as-code/main/Schemas/global-settings-schema.json",
  "pacOwnerId": "<unique-guid>",
  "pacEnvironments": [
    {
      "pacSelector": "epac-dev",
      "cloud": "AzureCloud",
      "tenantId": "<tenant-id>",
      "deploymentRootScope": "/providers/Microsoft.Management/managementGroups/<dev-mg>",
      "desiredState": {
        "strategy": "ownedOnly",
        "keepDfcSecurityAssignments": false
      },
      "managedIdentityLocation": "<region>"
    },
    {
      "pacSelector": "tenant",
      "cloud": "AzureCloud",
      "tenantId": "<tenant-id>",
      "deploymentRootScope": "/providers/Microsoft.Management/managementGroups/<prod-mg>",
      "desiredState": {
        "strategy": "full",
        "keepDfcSecurityAssignments": false
      },
      "managedIdentityLocation": "<region>"
    }
  ]
}
```

**Key Configuration Elements:**
- `pacOwnerId`: Unique identifier for this EPAC instance
- `pacSelector`: Environment identifier (epac-dev, tenant)
- `deploymentRootScope`: Management group where policies are deployed
- `desiredState.strategy`: 
  - `ownedOnly` for dev (doesn't delete non-EPAC policies)
  - `full` for prod (enforces complete desired state)
- `managedIdentityLocation`: Azure region for managed identities

#### nist-800-53-assignments.jsonc

Hierarchical policy assignment structure:

```jsonc
{
  "$schema": "https://raw.githubusercontent.com/Azure/enterprise-azure-policy-as-code/main/Schemas/policy-assignment-schema.json",
  "nodeName": "/Security/",
  "parameterFile": "nist-800-53-parameters.csv",
  "definitionEntryList": [
    {
      "policySetId": "/providers/Microsoft.Authorization/policySetDefinitions/179d1daa-458f-4e47-8086-2a68d0d6c38f",
      "displayName": "NIST SP 800-53 Rev. 5",
      "assignment": {
        "append": true,
        "name": "nist-800-53-r5",
        "displayName": "NIST SP 800-53 Rev. 5",
        "description": "NIST SP 800-53 Rev. 5 Initiative."
      }
    }
  ],
  "children": [
    {
      "nodeName": "Prod/",
      "assignment": {
        "name": "pr-",
        "displayName": "Prod ",
        "description": "Prod Environment controls enforcement with "
      },
      "parameterSelector": "prod",
      "scope": {
        "epac-dev": ["/providers/Microsoft.Management/managementGroups/<dev-prod-mg>"],
        "tenant": ["/providers/Microsoft.Management/managementGroups/<prod-mg>"]
      }
    },
    {
      "nodeName": "Nonprod/",
      "assignment": {
        "name": "tst-",
        "displayName": "Nonprod ",
        "description": "Nonprod Environment controls enforcement with "
      },
      "parameterSelector": "nonprod",
      "scope": {
        "epac-dev": ["/providers/Microsoft.Management/managementGroups/<dev-nonprod-mg>"],
        "tenant": ["/providers/Microsoft.Management/managementGroups/<nonprod-mg>"]
      }
    }
  ]
}
```

**Assignment Structure:**
- Root node defines the policy set and parameter file
- Child nodes define environment-specific scopes
- `parameterSelector` links to CSV columns for environment-specific parameters
- `append: true` concatenates parent and child assignment properties

#### nist-800-53-parameters.csv

CSV file structure for NIST 800-53 policy parameters (filtered to include ONLY NIST 800-53 policies):

```csv
"name","referencePath","policyType","category","displayName","description","groupNames","policySets","allowedEffects","prodEffect","nonprodEffect","prodParameters","nonprodParameters"
"<policy-guid>","","BuiltIn","<category>","<display-name>","<description>","NIST_SP_800-53_R5_<control>","NIST-800-53: <effect>","override: <effects>","<prod-effect>","<nonprod-effect>","<prod-params-json>","<nonprod-params-json>"
```

**CSV Columns:**
- `name`: Policy definition GUID
- `groupNames`: NIST control families (e.g., NIST_SP_800-53_R5_AC-4, NIST_SP_800-53_R5_SC-7)
- `policySets`: Must contain "NIST-800-53" (filter out ASB, PCI-DSS, etc.)
- `prodEffect`/`nonprodEffect`: Effect override per environment (Audit, Deny, Disabled, AuditIfNotExists, DeployIfNotExists)
- `prodParameters`/`nonprodParameters`: JSON-formatted parameters per environment

**Filtering Rules:**
- Include ONLY rows where `policySets` column contains "NIST-800-53"
- Exclude rows with only "ASB:" (Azure Security Benchmark)
- Exclude rows with only "PCI-DSS:"
- Keep rows with both "ASB:" and "NIST-800-53:" (multi-framework policies)

**Example NIST 800-53 Policy Row:**
```csv
"ef619a2c-cc4d-4d03-b2ba-8c94a834d85b","","BuiltIn","API Management","API Management services should use a virtual network","...","NIST_SP_800-53_R5_AC-4,NIST_SP_800-53_R5_SC-7,NIST_SP_800-53_R5_SC-7(3)","NIST-800-53: Audit (Policy Default)","override: Deny, Audit, Disabled","Audit","Audit","",""
```

### 3. GitHub Actions Workflows

#### Workflow Components

**epac-dev-workflow.yml**
- Triggers on PR to main with changes in Definitions/
- Deploys to epac-dev environment
- No approval gates (for rapid testing)

**epac-tenant-workflow.yml**
- Triggers on PR merge to main
- Deploys to production tenant
- Requires approval for policy and role deployments

**Reusable Templates:**
- `plan.yml`: Generates deployment plans
- `deploy-policy.yml`: Deploys policy resources
- `deploy-roles.yml`: Deploys role assignments

#### GitHub Environments

| Environment | Purpose | Secrets Required |
|-------------|---------|------------------|
| EPAC-DEV | Dev planning and deployment | AZURE_CLIENT_ID, AZURE_TENANT_ID |
| TENANT-PLAN | Prod plan generation | AZURE_CLIENT_ID, AZURE_TENANT_ID |
| TENANT-DEPLOY-POLICY | Prod policy deployment | AZURE_CLIENT_ID, AZURE_TENANT_ID |
| TENANT-DEPLOY-ROLES | Prod role deployment | AZURE_CLIENT_ID, AZURE_TENANT_ID |

**Environment Protection Rules:**
- TENANT-DEPLOY-POLICY: Required reviewers, branch restriction to main
- TENANT-DEPLOY-ROLES: Required reviewers, branch restriction to main

### 4. Authentication

#### GitHub Actions (OIDC)

Uses Azure AD Workload Identity Federation:

```yaml
- name: Azure Login
  uses: azure/login@v2
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    enable-AzPSSession: true
    allow-no-subscriptions: true
```

**Service Principal Requirements:**
- Federated credential configured for GitHub repository
- Permissions: Reader, Resource Policy Contributor, Role Based Access Control Administrator
- Scoped to deployment root management group

#### Local Scripts

Supports multiple authentication methods:

1. **Service Principal with Secret:**
```powershell
$credential = Get-Credential
Connect-AzAccount -ServicePrincipal -Credential $credential -Tenant $tenantId
```

2. **Service Principal with Certificate:**
```powershell
Connect-AzAccount -ServicePrincipal -CertificateThumbprint $thumbprint -ApplicationId $appId -Tenant $tenantId
```

3. **User Authentication:**
```powershell
Connect-AzAccount -Tenant $tenantId
```

### 5. PowerShell Scripts

#### Build-DeploymentPlans.ps1

**Purpose:** Generate deployment plans

**Parameters:**
- `-PacEnvironmentSelector`: Environment to target (epac-dev, tenant)
- `-DefinitionsRootFolder`: Path to Definitions folder (default: ./Definitions)
- `-OutputFolder`: Path for plan output (default: ./Output)
- `-DevOpsType`: Set to "ado" or "github" for CI/CD context

**Output:**
- `policy-plan.json`: Policy changes to be deployed
- `roles-plan.json`: Role assignment changes

**Usage:**
```powershell
Build-DeploymentPlans -PacEnvironmentSelector "epac-dev" -InformationAction Continue
```

#### Deploy-PolicyPlan.ps1

**Purpose:** Deploy policy resources from plan

**Parameters:**
- `-PacEnvironmentSelector`: Environment to target
- `-InputFolder`: Path to plan files (default: ./Output)
- `-DefinitionsRootFolder`: Path to Definitions folder

**Actions:**
- Creates/updates policy definitions
- Creates/updates policy set definitions
- Creates/updates policy assignments
- Deletes removed policy resources

**Usage:**
```powershell
Deploy-PolicyPlan -PacEnvironmentSelector "epac-dev" -InformationAction Continue
```

#### Deploy-RolesPlan.ps1

**Purpose:** Deploy role assignments from plan

**Parameters:**
- `-PacEnvironmentSelector`: Environment to target
- `-InputFolder`: Path to plan files (default: ./Output)
- `-DefinitionsRootFolder`: Path to Definitions folder

**Actions:**
- Creates role assignments for managed identities
- Assigns required permissions for policy enforcement

**Usage:**
```powershell
Deploy-RolesPlan -PacEnvironmentSelector "epac-dev" -InformationAction Continue
```

## Data Models

### Policy Assignment Node Structure

```
Root Node (Security/)
├── Policy Set Definition Reference
├── Parameter File Reference
└── Children
    ├── Prod Node
    │   ├── Assignment Name Prefix
    │   ├── Parameter Selector
    │   └── Scope (per environment)
    └── Nonprod Node
        ├── Assignment Name Prefix
        ├── Parameter Selector
        └── Scope (per environment)
```

### Deployment Plan Structure

**policy-plan.json:**
```json
{
  "policyDefinitions": {
    "new": [],
    "update": [],
    "delete": []
  },
  "policySetDefinitions": {
    "new": [],
    "update": [],
    "delete": []
  },
  "policyAssignments": {
    "new": [
      {
        "id": "<assignment-id>",
        "name": "<assignment-name>",
        "displayName": "<display-name>",
        "description": "<description>",
        "policyDefinitionId": "<policy-set-id>",
        "scope": "<scope>",
        "parameters": {},
        "identity": {
          "type": "SystemAssigned",
          "location": "<region>"
        }
      }
    ],
    "update": [],
    "delete": []
  }
}
```

**roles-plan.json:**
```json
{
  "roleAssignments": {
    "new": [
      {
        "principalId": "<managed-identity-id>",
        "roleDefinitionId": "<role-id>",
        "scope": "<scope>"
      }
    ],
    "delete": []
  }
}
```

## Error Handling

### GitHub Actions Error Handling

1. **Plan Generation Failures:**
   - Workflow fails if Build-DeploymentPlans returns non-zero exit code
   - Error details logged to workflow output
   - No deployment jobs triggered

2. **Deployment Failures:**
   - Policy deployment failures halt workflow
   - Role deployment only runs if policy deployment succeeds
   - Failed deployments require manual intervention

3. **Authentication Failures:**
   - OIDC token acquisition failures stop workflow immediately
   - Clear error messages indicate misconfigured federated credentials

### Local Script Error Handling

1. **Authentication Errors:**
   - Scripts check for active Azure context before execution
   - Prompt user to authenticate if not connected

2. **Plan Generation Errors:**
   - Validate Definitions folder structure
   - Check for required files (global-settings.jsonc, assignment files)
   - Report missing or malformed configuration

3. **Deployment Errors:**
   - Validate plan files exist before deployment
   - Report Azure API errors with context
   - Support -WhatIf mode for dry-run testing

### Error Recovery

1. **Rollback Strategy:**
   - Use git history to revert to previous working state
   - Redeploy from previous commit
   - EPAC will reconcile to desired state

2. **Partial Deployment Failures:**
   - Policy deployments are idempotent
   - Re-running deployment will complete partial deployments
   - Failed resources are retried on next run

## Testing Strategy

### Unit Testing

**Not applicable** - This is a configuration-based solution with no custom code requiring unit tests.

### Integration Testing

1. **Dev Environment Testing:**
   - Deploy to epac-dev environment first
   - Validate policy assignments created correctly
   - Verify parameters applied as expected
   - Check role assignments for managed identities

2. **Plan Validation:**
   - Review generated plans before production deployment
   - Verify only expected changes are included
   - Check for unintended deletions

3. **Local Script Testing:**
   - Test Build-DeploymentPlans locally before committing
   - Validate plan output matches expectations
   - Test deployment to dev environment from local machine

### End-to-End Testing

1. **GitHub Actions Workflow Testing:**
   - Create test PR with policy changes
   - Verify plan generation succeeds
   - Merge PR and validate deployment to epac-dev
   - Promote changes to production after validation

2. **Compliance Validation:**
   - Use Azure Policy Compliance dashboard
   - Verify NIST 800-53 policies are assigned
   - Check compliance status of resources
   - Validate exemptions are processed correctly

3. **Role Assignment Validation:**
   - Verify managed identities created for assignments
   - Check role assignments at correct scopes
   - Validate permissions for policy enforcement (e.g., DeployIfNotExists, Modify effects)

### Testing Checklist

- [ ] Global settings validate against schema
- [ ] Policy assignments validate against schema
- [ ] CSV parameters parse correctly
- [ ] Plan generation succeeds for both environments
- [ ] GitHub Actions workflows trigger correctly
- [ ] OIDC authentication succeeds
- [ ] Policy deployment completes without errors
- [ ] Role deployment completes without errors
- [ ] Policies appear in Azure Portal
- [ ] Compliance evaluation begins
- [ ] Local scripts can authenticate and deploy
- [ ] Rollback process works correctly

## Security Considerations

### Service Principal Permissions

**Minimum Required Permissions:**
- Reader (at deployment root scope)
- Resource Policy Contributor (at deployment root scope)
- Role Based Access Control Administrator (at deployment root scope)

**Federated Credential Configuration:**
- Subject: `repo:<org>/<repo>:environment:<environment-name>`
- Issuer: `https://token.actions.githubusercontent.com`
- Audience: `api://AzureADTokenExchange`

### Secret Management

**GitHub Secrets:**
- AZURE_CLIENT_ID: Service principal application ID
- AZURE_TENANT_ID: Azure AD tenant ID
- No client secrets stored (using OIDC)

**Local Development:**
- Use Azure Key Vault for service principal secrets
- Avoid storing credentials in scripts or environment variables
- Use certificate-based authentication when possible

### Network Security

**GitHub Actions Runners:**
- Use GitHub-hosted runners (no network restrictions needed)
- Or configure self-hosted runners with Azure connectivity

**Local Development:**
- Ensure network connectivity to Azure management endpoints
- May require VPN or ExpressRoute for restricted environments

## Deployment Sequence

### Initial Setup

1. Create Azure AD service principals with federated credentials
2. Assign required permissions to service principals
3. Create GitHub environments with secrets
4. Configure environment protection rules
5. Customize global-settings.jsonc with tenant/management group IDs
6. Customize nist-800-53-assignments.jsonc with scopes
7. Review and adjust nist-800-53-parameters.csv

### First Deployment

1. Deploy to epac-dev environment:
   - Push changes to feature branch
   - Create PR to main
   - Review plan in PR
   - Merge PR to trigger deployment

2. Validate dev deployment:
   - Check Azure Portal for policy assignments
   - Verify compliance evaluation starts
   - Test policy enforcement

3. Deploy to production:
   - Changes automatically deploy after dev merge
   - Approve policy deployment
   - Approve role deployment
   - Validate production deployment

### Ongoing Changes

1. Modify policy parameters in CSV file
2. Commit and push to feature branch
3. Review plan in PR
4. Merge to deploy to dev
5. Validate and promote to production

## Maintenance and Operations

### Regular Maintenance Tasks

1. **Policy Parameter Updates:**
   - Review compliance reports
   - Adjust effects (Audit → Deny) as needed
   - Update parameters for new requirements

2. **NIST 800-53 Updates:**
   - Monitor for updates to built-in policy set
   - Test updates in dev environment
   - Deploy to production after validation

3. **Service Principal Rotation:**
   - Rotate federated credentials annually
   - Update GitHub secrets
   - Test authentication after rotation

### Monitoring

1. **GitHub Actions:**
   - Monitor workflow runs for failures
   - Review deployment logs
   - Set up notifications for failed deployments

2. **Azure Policy Compliance:**
   - Review compliance dashboard regularly
   - Investigate non-compliant resources
   - Create exemptions as needed

3. **Audit Logs:**
   - Review Azure Activity Log for policy changes
   - Monitor for unauthorized modifications
   - Track deployment history in git

### Troubleshooting

**Common Issues:**

1. **Plan generation fails:**
   - Check global-settings.jsonc syntax
   - Verify management group IDs exist
   - Validate CSV parameter file format

2. **Deployment fails:**
   - Check service principal permissions
   - Verify network connectivity
   - Review Azure API error messages

3. **Policies not enforcing:**
   - Check policy effect (Audit vs Deny)
   - Verify role assignments for managed identities
   - Check for policy exemptions

4. **Local scripts fail:**
   - Verify Azure PowerShell module installed
   - Check authentication status
   - Ensure correct PAC environment selector
