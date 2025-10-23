# Requirements Document

## Introduction

This feature focuses on creating a streamlined Enterprise Policy as Code (EPAC) deployment **exclusively for NIST 800-53 Rev. 5** compliance framework. The solution will use GitHub Actions for CI/CD automation while maintaining the ability to deploy and manage policies locally from a developer's computer to Azure cloud.

**Key Simplification**: NIST 800-53 Rev. 5 is a **built-in Azure policy set** (ID: 179d1daa-458f-4e47-8086-2a68d0d6c38f), which means:
- No custom policy definitions needed (no `policyDefinitions/` folder)
- No custom policy set definitions needed (no `policySetDefinitions/` folder)
- Only policy **assignments** and **parameters** need to be configured
- Significantly reduced complexity compared to multi-framework deployments

The implementation will strip away all other compliance frameworks (Azure Security Benchmark, PCI-DSS, etc.) and focus solely on NIST 800-53, reducing complexity and maintenance overhead.

## Requirements

### Requirement 1: NIST 800-53 Only Policy Definitions

**User Story:** As a compliance administrator, I want to deploy only NIST 800-53 Rev. 5 policies, so that I can maintain a focused compliance posture without unnecessary policy overhead.

#### Acceptance Criteria

1. WHEN the policy definitions are configured THEN the system SHALL include only NIST 800-53 Rev. 5 policy set (ID: /providers/Microsoft.Authorization/policySetDefinitions/179d1daa-458f-4e47-8086-2a68d0d6c38f)
2. WHEN the policy definitions are configured THEN the system SHALL exclude Azure Security Benchmark policy set
3. WHEN the policy definitions are configured THEN the system SHALL exclude PCI-DSS policy set
4. WHEN the policy definitions are configured THEN the system SHALL exclude any other compliance framework policy sets not related to NIST 800-53
5. WHEN policy assignments are created THEN they SHALL reference only NIST 800-53 Rev. 5 definitions

### Requirement 2: GitHub Actions CI/CD Pipeline

**User Story:** As a DevOps engineer, I want automated deployment through GitHub Actions, so that policy changes are consistently deployed with proper approval gates.

#### Acceptance Criteria

1. WHEN code is pushed to a feature branch THEN the system SHALL trigger a plan generation workflow
2. WHEN a pull request is merged to main THEN the system SHALL trigger the deployment workflow
3. WHEN the deployment workflow runs THEN it SHALL execute in the following sequence: plan, deploy policies, deploy roles
4. WHEN deploying to production THEN the system SHALL require manual approval before policy deployment
5. WHEN deploying to production THEN the system SHALL require manual approval before role deployment
6. WHEN the workflow completes THEN it SHALL provide deployment status and summary
7. IF deployment fails THEN the system SHALL halt execution and report errors

### Requirement 3: Local Management Capability

**User Story:** As a policy administrator, I want to deploy and manage policies from my local computer, so that I can test changes and perform emergency deployments without relying on CI/CD pipelines.

#### Acceptance Criteria

1. WHEN running local deployment scripts THEN the system SHALL authenticate to Azure using service principal or user credentials
2. WHEN running Build-DeploymentPlans locally THEN it SHALL generate plan files in the Output folder
3. WHEN running Deploy-PolicyPlan locally THEN it SHALL deploy policies based on the generated plan
4. WHEN running Deploy-RolesPlan locally THEN it SHALL deploy role assignments based on the generated plan
5. WHEN running local scripts THEN they SHALL target the same environments as GitHub Actions (epac-dev, tenant)
6. WHEN local deployment completes THEN it SHALL provide the same validation and reporting as CI/CD deployments

### Requirement 4: Environment Configuration

**User Story:** As a system architect, I want separate development and production environments, so that I can test policy changes before production deployment.

#### Acceptance Criteria

1. WHEN global settings are configured THEN the system SHALL define an epac-dev environment
2. WHEN global settings are configured THEN the system SHALL define a tenant (production) environment
3. WHEN environments are defined THEN each SHALL specify its own deployment root scope (management group)
4. WHEN environments are defined THEN each SHALL specify its own tenant ID
5. WHEN environments are defined THEN each SHALL specify managed identity location
6. WHEN policy assignments are scoped THEN they SHALL support different scopes for epac-dev and tenant environments

### Requirement 5: Simplified Directory Structure

**User Story:** As a developer, I want a clean directory structure with only NIST 800-53 related files, so that the repository is easy to navigate and maintain.

#### Acceptance Criteria

1. WHEN the repository is structured THEN it SHALL contain Definitions/policyAssignments/ with only NIST 800-53 assignments
2. WHEN the repository is structured THEN it SHALL contain Definitions/policyDocumentations/ (optional for compliance reports)
3. WHEN the repository is structured THEN it SHALL contain Definitions/policyExemptions/ (optional for exemption management)
4. WHEN the repository is structured THEN it SHALL NOT contain policyDefinitions/ or policySetDefinitions/ folders (NIST 800-53 is built-in)
5. WHEN the repository is structured THEN it SHALL contain GitHub Actions workflows in .github/workflows
6. WHEN the repository is structured THEN it SHALL exclude Azure Security Benchmark, PCI-DSS, and other framework files
7. WHEN documentation is provided THEN it SHALL focus exclusively on NIST 800-53 deployment and management

### Requirement 6: Service Principal Authentication

**User Story:** As a security administrator, I want to use service principals for authentication, so that deployments are secure and auditable.

#### Acceptance Criteria

1. WHEN GitHub Actions workflows run THEN they SHALL authenticate using federated credentials (OIDC)
2. WHEN local scripts run THEN they SHALL support service principal authentication with client secret or certificate
3. WHEN service principals are configured THEN they SHALL have minimum required permissions (Reader, Policy Contributor, RBAC Administrator)
4. WHEN authentication fails THEN the system SHALL provide clear error messages
5. WHEN GitHub environments are configured THEN each SHALL store AZURE_CLIENT_ID and AZURE_TENANT_ID as secrets

### Requirement 7: Parameter Management

**User Story:** As a policy administrator, I want to manage NIST 800-53 policy parameters through CSV files, so that I can easily configure hundreds of policy settings without complex JSON.

#### Acceptance Criteria

1. WHEN policy assignments reference parameters THEN they SHALL use a CSV parameter file
2. WHEN the CSV parameter file is structured THEN it SHALL include columns for policy name, effect, and parameters
3. WHEN parameters are defined THEN they SHALL support different values for prod and nonprod environments using parameterSelector
4. WHEN the CSV file is updated THEN the system SHALL validate the format before deployment
5. WHEN parameters are applied THEN they SHALL override default policy set parameters

### Requirement 8: Deployment Validation and Rollback

**User Story:** As a change manager, I want to review deployment plans before execution, so that I can prevent unintended policy changes.

#### Acceptance Criteria

1. WHEN Build-DeploymentPlans executes THEN it SHALL generate a policy-plan.json file
2. WHEN Build-DeploymentPlans executes THEN it SHALL generate a roles-plan.json file
3. WHEN the plan is generated THEN it SHALL show additions, modifications, and deletions
4. WHEN reviewing the plan THEN administrators SHALL be able to approve or reject before deployment
5. IF a deployment needs to be reverted THEN the system SHALL support rolling back to previous policy state through git history

### Requirement 9: Multi-Scope Assignment Support

**User Story:** As an enterprise architect, I want to assign NIST 800-53 policies to different management groups, so that I can enforce compliance at prod and nonprod levels.

#### Acceptance Criteria

1. WHEN policy assignments are configured THEN they SHALL support hierarchical node structure
2. WHEN assignments target prod THEN they SHALL use "pr-" prefix and target mg-prod management group
3. WHEN assignments target nonprod THEN they SHALL use "tst-" prefix and target mg-nonprod management group
4. WHEN assignments are created THEN they SHALL inherit from parent node configuration
5. WHEN assignments are deployed THEN they SHALL respect scope and notScope configurations
