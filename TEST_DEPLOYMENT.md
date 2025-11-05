# Test Deployment

This file is created to trigger the GitHub Actions workflow for the initial test deployment.

## Deployment Configuration

- **Tenant ID**: e1f3e196-aa55-4709-9c55-0e334c0b444f
- **Dev Management Group**: P4CX-dev
- **Production Management Group**: Tenant Root (e1f3e196-aa55-4709-9c55-0e334c0b444f)
- **IT Management Group**: it (for production policies)
- **Sales Management Group**: sales (for non-production policies)

## Service Principals Created

1. **epac-dev-owner** (eb80f8f1-1cbb-4a17-b2c5-2193f1b62687)
   - Environment: EPAC-DEV
   - Scope: P4CX-dev
   - Roles: Reader, Resource Policy Contributor, RBAC Administrator

2. **tenant-plan** (c5f77cd6-66da-4481-95fe-614d0ddb5822)
   - Environment: TENANT-PLAN
   - Scope: Tenant Root
   - Roles: Reader

3. **tenant-policy** (cc372281-fd63-4160-89b4-2896293d3573)
   - Environment: TENANT-DEPLOY-POLICY
   - Scope: Tenant Root
   - Roles: Reader, Resource Policy Contributor

4. **tenant-roles** (6de0bbc8-c63d-4914-9686-927d27288889)
   - Environment: TENANT-DEPLOY-ROLES
   - Scope: Tenant Root
   - Roles: Reader, RBAC Administrator

## GitHub Environments Configured

All environments have been created with appropriate secrets:
- EPAC-DEV (no approval required)
- TENANT-PLAN (no approval required)
- TENANT-DEPLOY-POLICY (approval required for production)
- TENANT-DEPLOY-ROLES (approval required for production)

## Initial Policy State

All NIST 800-53 policies are currently set to "Audit" mode for safe initial deployment.