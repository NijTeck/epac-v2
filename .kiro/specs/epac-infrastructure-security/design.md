# Design Document

## Overview

This design creates a comprehensive mapping between NIST 800-53 Rev. 5 technical controls and Azure Policy definitions, with all policies configured in **enforcement mode**. The solution includes:

1. **Control-to-Policy Mapping CSV**: Tracks which NIST controls are enforced by which Azure policies
2. **Enforcement Mode Configuration**: Updates the NIST 800-53 parameters CSV to use enforcement effects
3. **Policy Categorization**: Groups policies by NIST control families for easier management
4. **Compliance Tracking**: Enables monitoring of which controls are implemented vs. planned

### Key Design Principles

1. **Enforcement First**: All policies use Deny, DeployIfNotExists, Modify, or Append (not Audit)
2. **Traceability**: Every policy maps back to specific NIST 800-53 controls
3. **Measurable**: CSV tracking allows quantifying compliance coverage
4. **Actionable**: Clear implementation status for each control

## Architecture

### High-Level Flow

```
NIST 800-53 Controls
        ↓
Control-to-Policy Mapping (CSV)
        ↓
Azure Policy Definitions (Built-in)
        ↓
Policy Parameters (Enforcement Mode)
        ↓
Policy Assignments (EPAC)
        ↓
Azure Resources (Enforced Compliance)
```

### Component Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                  NIST 800-53 Control Mapping                 │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  nist-control-mapping.csv                            │  │
│  │  ┌────────────────────────────────────────────────┐ │  │
│  │  │ Control ID │ Policy ID │ Effect │ Status       │ │  │
│  │  │ AC-4       │ xxx-xxx   │ Deny   │ Implemented  │ │  │
│  │  │ SC-7       │ yyy-yyy   │ DINE   │ Implemented  │ │  │
│  │  └────────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────┘  │
│                          ↓                                   │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  nist-800-53-parameters.csv (Updated)                │  │
│  │  ┌────────────────────────────────────────────────┐ │  │
│  │  │ Policy │ prodEffect │ nonprodEffect │ Notes    │ │  │
│  │  │ xxx    │ Deny       │ Deny          │ AC-4     │ │  │
│  │  │ yyy    │ DINE       │ Audit         │ SC-7     │ │  │
│  │  └────────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────┘  │
│                          ↓                                   │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  EPAC Deployment                                      │  │
│  │  - Policy Assignments with Enforcement                │  │
│  │  - Managed Identities for DINE/Modify                │  │
│  │  - Role Assignments for Remediation                  │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Components and Interfaces

### 1. NIST Control-to-Policy Mapping CSV

**File**: `Definitions/nist-control-mapping.csv`

**Purpose**: Master tracking file that maps NIST 800-53 controls to Azure Policy definitions

**Schema**:

```csv
"controlId","controlFamily","controlName","controlDescription","policyId","policyName","policyEffect","implementationStatus","enforcementScope","notes"
```

**Column Definitions**:

| Column | Description | Example |
|--------|-------------|---------|
| controlId | NIST 800-53 control identifier | AC-4, SC-7, IA-2 |
| controlFamily | NIST control family | Access Control, System and Communications Protection |
| controlName | Short control name | Information Flow Enforcement, Boundary Protection |
| controlDescription | What the control requires | Enforce approved authorizations for controlling information flow |
| policyId | Azure Policy definition GUID | ef619a2c-cc4d-4d03-b2ba-8c94a834d85b |
| policyName | Azure Policy display name | API Management services should use a virtual network |
| policyEffect | Enforcement effect | Deny, DeployIfNotExists, Modify, Append |
| implementationStatus | Current status | Implemented, Planned, Not Applicable |
| enforcementScope | Where policy is enforced | Prod, Nonprod, Both |
| notes | Implementation details | Enforces network isolation per AC-4 |

**Example Rows**:

```csv
"AC-4","Access Control","Information Flow Enforcement","Enforce approved authorizations for controlling information flow","ef619a2c-cc4d-4d03-b2ba-8c94a834d85b","API Management services should use a virtual network","Deny","Implemented","Both","Enforces network boundary controls"
"SC-7","System and Communications Protection","Boundary Protection","Monitor and control communications at external boundaries","ca610c1d-041c-4332-9d88-7ed3094967c7","App Configuration should use private link","DeployIfNotExists","Implemented","Prod","Automatically deploys private endpoints"
"IA-2","Identification and Authentication","Identification and Authentication (Organizational Users)","Uniquely identify and authenticate organizational users","71ef260a-8f18-47b7-abcb-62d0673d94dc","Azure AI Services resources should have key access disabled","Deny","Implemented","Both","Enforces Azure AD authentication only"
```

### 2. Updated NIST 800-53 Parameters CSV

**File**: `Definitions/policyAssignments/nist-800-53-parameters.csv`

**Changes**: Update `prodEffect` and `nonprodEffect` columns to use enforcement modes

**Enforcement Effect Mapping**:

| Current (Audit Mode) | Updated (Enforcement Mode) | Use Case |
|---------------------|---------------------------|----------|
| Audit | Deny | Prevent non-compliant resource creation |
| Audit | DeployIfNotExists | Auto-deploy missing security configurations |
| Audit | Modify | Auto-correct configuration drift |
| Audit | Append | Auto-add required tags/properties |
| AuditIfNotExists | DeployIfNotExists | Auto-deploy missing resources |

**Example Updates**:

```csv
# Before (Audit Mode)
"ef619a2c-cc4d-4d03-b2ba-8c94a834d85b","API Management services should use a virtual network","Audit","Audit"

# After (Enforcement Mode)
"ef619a2c-cc4d-4d03-b2ba-8c94a834d85b","API Management services should use a virtual network","Deny","Audit"
```

### 3. NIST Control Family Groupings

Group policies by NIST 800-53 control families for easier management:

#### Access Control (AC)

- AC-2: Account Management
- AC-3: Access Enforcement
- AC-4: Information Flow Enforcement
- AC-6: Least Privilege
- AC-17: Remote Access

**Example Policies**:
- Managed identity should be used (AC-2, AC-3)
- Network isolation policies (AC-4)
- Private endpoint policies (AC-4, AC-17)

#### Identification and Authentication (IA)

- IA-2: Identification and Authentication (Organizational Users)
- IA-4: Identifier Management
- IA-5: Authenticator Management

**Example Policies**:
- Disable local authentication (IA-2)
- Require Azure AD authentication (IA-2)
- MFA requirements (IA-2)

#### System and Communications Protection (SC)

- SC-7: Boundary Protection
- SC-8: Transmission Confidentiality and Integrity
- SC-12: Cryptographic Key Establishment and Management
- SC-13: Cryptographic Protection
- SC-28: Protection of Information at Rest

**Example Policies**:
- TLS version requirements (SC-8)
- Encryption at rest (SC-28)
- Customer-managed keys (SC-12)
- Network security groups (SC-7)

#### Audit and Accountability (AU)

- AU-2: Event Logging
- AU-6: Audit Record Review, Analysis, and Reporting
- AU-12: Audit Record Generation

**Example Policies**:
- Diagnostic settings required (AU-2, AU-12)
- Log Analytics workspace (AU-6)
- Activity log retention (AU-2)

#### Configuration Management (CM)

- CM-2: Baseline Configuration
- CM-6: Configuration Settings
- CM-7: Least Functionality

**Example Policies**:
- Allowed resource types (CM-7)
- Required tags (CM-2)
- Configuration baselines (CM-6)

#### System and Information Integrity (SI)

- SI-2: Flaw Remediation
- SI-3: Malicious Code Protection
- SI-4: System Monitoring

**Example Policies**:
- System updates required (SI-2)
- Antimalware deployment (SI-3)
- Monitoring agents required (SI-4)

## Data Models

### Control Mapping Data Model

```typescript
interface ControlMapping {
  controlId: string;              // "AC-4"
  controlFamily: string;          // "Access Control"
  controlName: string;            // "Information Flow Enforcement"
  controlDescription: string;     // Full control description
  policyId: string;               // Azure Policy GUID
  policyName: string;             // Policy display name
  policyEffect: PolicyEffect;     // Deny | DeployIfNotExists | Modify | Append
  implementationStatus: Status;   // Implemented | Planned | Not Applicable
  enforcementScope: Scope;        // Prod | Nonprod | Both
  notes: string;                  // Implementation details
}

enum PolicyEffect {
  Deny = "Deny",
  DeployIfNotExists = "DeployIfNotExists",
  Modify = "Modify",
  Append = "Append",
  Audit = "Audit"  // Only for informational policies
}

enum Status {
  Implemented = "Implemented",
  Planned = "Planned",
  NotApplicable = "Not Applicable"
}

enum Scope {
  Prod = "Prod",
  Nonprod = "Nonprod",
  Both = "Both"
}
```

### Policy Effect Decision Tree

```
Is the control preventive?
├─ Yes → Can it block resource creation?
│  ├─ Yes → Use Deny
│  └─ No → Can it deploy missing config?
│     ├─ Yes → Use DeployIfNotExists
│     └─ No → Use Modify or Append
└─ No → Is it detective?
   ├─ Yes → Can it auto-remediate?
   │  ├─ Yes → Use DeployIfNotExists
   │  └─ No → Use Audit (informational only)
   └─ No → Use Audit
```

## Implementation Strategy

### Phase 1: Analyze Current NIST 800-53 Policies

1. **Extract policies from existing CSV**:
   - Read `Definitions/policyAssignments/nist-800-53-parameters.csv`
   - Filter policies with NIST control groups
   - Identify current effects (mostly Audit)

2. **Group by control family**:
   - Parse `groupNames` column for NIST_SP_800-53_R5_* patterns
   - Extract control IDs (AC-4, SC-7, etc.)
   - Group policies by control family

3. **Identify enforcement candidates**:
   - Policies with `allowedEffects` containing Deny
   - Policies with `allowedEffects` containing DeployIfNotExists
   - Policies with `allowedEffects` containing Modify

### Phase 2: Create Control Mapping

1. **Build mapping CSV**:
   - For each NIST policy, extract control IDs
   - Look up control names and descriptions
   - Determine appropriate enforcement effect
   - Set implementation status

2. **Prioritize by control family**:
   - Start with AC (Access Control) - highest priority
   - Then SC (System and Communications Protection)
   - Then IA (Identification and Authentication)
   - Then AU (Audit and Accountability)
   - Finally CM, SI, and others

### Phase 3: Update Parameters for Enforcement

1. **Update prodEffect column**:
   - Change Audit → Deny for preventive controls
   - Change AuditIfNotExists → DeployIfNotExists for auto-remediation
   - Keep Audit only for informational policies

2. **Staged rollout**:
   - Start with nonprodEffect = Audit (testing)
   - After validation, update prodEffect = Deny/DINE
   - Finally update nonprodEffect to match prod

### Phase 4: Deploy and Monitor

1. **Deploy to epac-dev first**:
   - Test enforcement policies in dev environment
   - Verify no unintended resource blocks
   - Check remediation tasks work correctly

2. **Monitor compliance**:
   - Review Azure Policy compliance dashboard
   - Check for blocked deployments (Deny policies)
   - Verify remediation tasks (DINE policies)

3. **Deploy to production**:
   - After successful dev testing
   - With approval gates
   - Monitor for issues

## Testing Strategy

### Enforcement Testing

1. **Deny Policy Testing**:
   - Attempt to create non-compliant resource
   - Verify creation is blocked
   - Verify error message is clear

2. **DeployIfNotExists Testing**:
   - Create resource without required configuration
   - Verify remediation task is created
   - Verify configuration is deployed automatically

3. **Modify Policy Testing**:
   - Create resource with incorrect configuration
   - Verify configuration is automatically corrected
   - Verify resource remains functional

### Compliance Testing

1. **Coverage Testing**:
   - Count NIST controls with mapped policies
   - Calculate coverage percentage
   - Identify gaps

2. **Effectiveness Testing**:
   - Deploy test resources
   - Verify policies enforce correctly
   - Check compliance dashboard

## Compliance Coverage Metrics

### Coverage Calculation

```
Total NIST 800-53 Technical Controls: ~200
Controls with Azure Policy Mapping: X
Coverage Percentage: (X / 200) * 100%
```

### Target Coverage by Control Family

| Control Family | Target Coverage | Priority |
|----------------|-----------------|----------|
| AC (Access Control) | 80% | High |
| SC (System and Communications Protection) | 75% | High |
| IA (Identification and Authentication) | 70% | High |
| AU (Audit and Accountability) | 90% | Medium |
| CM (Configuration Management) | 60% | Medium |
| SI (System and Information Integrity) | 50% | Low |

## Maintenance and Operations

### Regular Tasks

1. **Monthly**: Review new Azure Policy releases for NIST 800-53 coverage
2. **Quarterly**: Update control mapping with new policies
3. **Quarterly**: Review enforcement effectiveness
4. **Annually**: Full NIST 800-53 compliance audit

### Updating the Mapping

1. New Azure Policy released:
   - Check if it maps to NIST control
   - Add to control-mapping.csv
   - Update parameters CSV with enforcement effect
   - Deploy and test

2. Control not covered:
   - Document in mapping as "Not Applicable" or "Planned"
   - Consider custom policy if critical
   - Document compensating controls

## Security Considerations

### Enforcement Impact

- **Deny policies** can block legitimate deployments if misconfigured
- **DeployIfNotExists** requires managed identity with permissions
- **Modify policies** can change resource configurations unexpectedly

### Mitigation Strategies

1. **Test in dev first**: Always validate in epac-dev before production
2. **Exemptions process**: Have process for legitimate exceptions
3. **Monitoring**: Alert on blocked deployments for review
4. **Rollback plan**: Keep previous parameter CSV version for quick rollback

## Deliverables

1. **nist-control-mapping.csv**: Master control-to-policy mapping
2. **Updated nist-800-53-parameters.csv**: Enforcement mode configuration
3. **Control coverage report**: Metrics on NIST 800-53 coverage
4. **Deployment guide**: How to deploy enforcement mode policies
5. **Exemption process**: How to handle legitimate exceptions
