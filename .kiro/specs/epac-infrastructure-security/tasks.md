# Implementation Plan

- [x] 1. Analyze current NIST 800-53 policy assignments


  - Read Definitions/policyAssignments/nist-800-53-parameters.csv
  - Extract all policies with NIST control group names
  - Parse groupNames column to identify NIST control IDs (AC-4, SC-7, etc.)
  - Count total policies by control family
  - Identify policies currently in Audit mode that support enforcement
  - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.2_

- [x] 2. Create NIST control family reference data


  - Create reference data for NIST 800-53 control families (AC, SC, IA, AU, CM, SI)
  - Map control IDs to control names and descriptions
  - Identify technical controls (vs. administrative/physical)
  - Prioritize controls by enforcement criticality
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

- [x] 3. Build control-to-policy mapping CSV


  - Create Definitions/nist-control-mapping.csv with schema
  - For each NIST policy, extract control IDs from groupNames
  - Map policy GUID to policy display name
  - Determine appropriate enforcement effect (Deny, DeployIfNotExists, Modify, Append)
  - Set initial implementation status (Implemented for existing, Planned for new)
  - Add notes explaining how policy enforces the control
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8_

- [x] 4. Categorize policies by enforcement effect


  - Identify policies that support Deny effect (preventive controls)
  - Identify policies that support DeployIfNotExists effect (auto-remediation)
  - Identify policies that support Modify effect (configuration correction)
  - Identify policies that support Append effect (adding properties)
  - Document policies that only support Audit (informational only)
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 5. Update parameters CSV for enforcement mode


- [x] 5.1 Create backup of current parameters CSV


  - Copy nist-800-53-parameters.csv to nist-800-53-parameters-audit-mode.csv.bak
  - Document current state before enforcement changes
  - _Requirements: 3.1, 3.6_

- [x] 5.2 Update prodEffect column for high-priority controls


  - Update Access Control (AC) policies to enforcement mode
  - Update System and Communications Protection (SC) policies to enforcement mode
  - Update Identification and Authentication (IA) policies to enforcement mode
  - Keep nonprodEffect as Audit initially for testing
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.6_

- [x] 5.3 Update prodEffect column for medium-priority controls


  - Update Audit and Accountability (AU) policies to enforcement mode
  - Update Configuration Management (CM) policies to enforcement mode
  - Keep nonprodEffect as Audit initially for testing
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.6_

- [x] 6. Create compliance coverage report


  - Count total NIST 800-53 technical controls
  - Count controls with Azure Policy mappings
  - Calculate coverage percentage by control family
  - Identify gaps (controls without policy mappings)
  - Create Definitions/nist-compliance-coverage.csv with metrics
  - _Requirements: 10.1, 10.2, 10.3, 10.4_



- [ ] 7. Create enforcement deployment guide
  - Create ENFORCEMENT_MODE.md documentation
  - Document enforcement effect decision tree
  - Document testing procedures for each effect type
  - Document rollback procedures if enforcement causes issues
  - Include examples of Deny, DeployIfNotExists, Modify, and Append policies

  - _Requirements: 3.1, 3.2, 3.3, 3.4, 9.1, 9.2, 9.3, 9.4_

- [ ] 8. Create policy exemption process documentation
  - Create EXEMPTIONS.md documentation
  - Document when exemptions are appropriate
  - Document exemption approval workflow
  - Document how to create exemptions in EPAC

  - Include exemption tracking and review process
  - _Requirements: 9.4, 10.5_

- [ ] 9. Create automated remediation guide
  - Create REMEDIATION.md documentation
  - Document how DeployIfNotExists policies create remediation tasks
  - Document how to monitor remediation task status

  - Document how to manually trigger remediation
  - Include troubleshooting for failed remediation tasks
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

- [ ] 10. Create compliance monitoring dashboard guide
  - Create COMPLIANCE_MONITORING.md documentation
  - Document how to access Azure Policy compliance dashboard


  - Document how to filter by NIST 800-53 assignments
  - Document how to set up compliance alerts
  - Include PowerShell scripts for compliance reporting
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

- [x] 11. Validate enforcement mode configuration


  - Review control-mapping.csv for completeness
  - Verify all high-priority controls have enforcement policies
  - Check that enforcement effects are appropriate for each control
  - Validate that nonprod is set to Audit for initial testing
  - Confirm backup of audit-mode parameters exists
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

- [ ] 12. Create deployment checklist
  - Create ENFORCEMENT_DEPLOYMENT_CHECKLIST.md
  - Document pre-deployment validation steps
  - Document deployment sequence (dev first, then prod)
  - Document post-deployment monitoring steps
  - Include rollback procedures
  - Include success criteria for each phase
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 10.1, 10.2, 10.3, 10.4, 10.5_

- [ ] 13. Create custom policies for SI (System Integrity) controls
- [ ] 13.1 Create Defender for Cloud auto-enablement policy
  - Create custom policy definition for SI-3, SI-4 controls
  - Policy should deploy Defender plans (Servers, SQL, Storage, Key Vault, Resource Manager, App Service, Containers)
  - Use DeployIfNotExists effect with managed identity
  - Include parameters for plan selection and pricing tier
  - _Requirements: 2.1, 2.6, 3.2, 9.1_

- [ ] 13.2 Create threat detection monitoring policy
  - Create custom policy for SI-4 (System Monitoring)
  - Policy should ensure Defender for Cloud security contacts are configured
  - Policy should ensure email notifications are enabled for high severity alerts
  - Use DeployIfNotExists effect
  - _Requirements: 2.6, 3.2, 9.1_

- [ ] 13.3 Create vulnerability assessment policy
  - Create custom policy for SI-2 (Flaw Remediation)
  - Policy should deploy vulnerability assessment solution on VMs
  - Policy should deploy vulnerability assessment on SQL servers
  - Use DeployIfNotExists effect
  - _Requirements: 2.6, 3.2, 9.1_

- [ ] 14. Create custom policies for IA (Identity & Authentication) controls
- [ ] 14.1 Create Entra ID MFA audit policy
  - Create custom policy for IA-2 (Identification and Authentication)
  - Policy should audit whether Conditional Access policies exist for MFA
  - Use Audit effect (enforcement requires Entra ID Conditional Access)
  - Include documentation on manual Entra ID configuration steps
  - _Requirements: 2.3, 3.5, 10.1_

- [ ] 14.2 Create privileged access audit policy
  - Create custom policy for IA-2, AC-6 (Privileged Access)
  - Policy should audit whether Entra PIM is configured
  - Policy should audit whether privileged roles have PIM assignments
  - Use Audit effect (enforcement requires Entra PIM)
  - Include documentation on manual PIM configuration steps
  - _Requirements: 2.2, 2.3, 3.5, 10.1_

- [ ] 14.3 Create password policy audit
  - Create custom policy for IA-5 (Authenticator Management)
  - Policy should audit whether Entra ID password policies meet NIST requirements
  - Check minimum password length, complexity, history, age
  - Use Audit effect (enforcement requires Entra ID configuration)
  - Include documentation on manual Entra ID password policy configuration
  - _Requirements: 2.3, 3.5, 10.1_

- [ ] 15. Create comprehensive Guest Configuration deployment policy
- [ ] 15.1 Create VM Guest Configuration auto-deployment policy
  - Create custom policy that combines all Guest Configuration prerequisites
  - Policy should add system-assigned managed identity to all VMs
  - Policy should deploy Guest Configuration extension to Windows VMs
  - Policy should deploy Guest Configuration extension to Linux VMs
  - Policy should deploy Azure Monitor Agent to all VMs
  - Use Modify and DeployIfNotExists effects
  - _Requirements: 2.1, 2.2, 2.3, 3.2, 3.3, 9.1_

- [ ] 15.2 Create Guest Configuration compliance enforcement policy
  - Create custom policy for CM-6 (Configuration Settings)
  - Policy should enforce Windows security baseline configurations
  - Policy should enforce Linux security baseline configurations
  - Policy should enforce password policies on VMs
  - Use AuditIfNotExists effect (Guest Configuration is detective)
  - _Requirements: 2.6, 3.5, 10.1_

- [ ] 16. Create custom policy set for comprehensive NIST enforcement
- [ ] 16.1 Create enhanced NIST 800-53 policy set definition
  - Create custom policy set that includes built-in NIST 800-53 policies
  - Add custom SI policies (Defender for Cloud deployment)
  - Add custom IA policies (Entra ID auditing)
  - Add custom Guest Configuration policies
  - Include all prerequisite policies in single assignment
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 3.1, 3.2, 3.3_

- [ ] 16.2 Create policy assignment for enhanced NIST set
  - Create assignment file for custom policy set
  - Configure system-assigned managed identity
  - Set enforcement mode for all enforceable policies
  - Set audit mode for informational policies
  - Include parameters for Defender plans, Guest Configuration settings
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.6, 9.1_

- [ ] 17. Create documentation for custom policies
- [ ] 17.1 Create CUSTOM_POLICIES.md documentation
  - Document all custom policy definitions created
  - Explain why each custom policy was needed
  - Document policy effects and enforcement capabilities
  - Include deployment instructions
  - Include testing procedures
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 9.1, 9.2, 9.3, 9.4_

- [ ] 17.2 Create ENTRA_ID_CONFIGURATION.md documentation
  - Document Entra ID Conditional Access configuration for MFA
  - Document Entra PIM configuration for privileged access
  - Document Entra ID password policy configuration
  - Include step-by-step setup instructions
  - Include verification procedures
  - _Requirements: 2.3, 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_

- [ ] 17.3 Create DEFENDER_CONFIGURATION.md documentation
  - Document Defender for Cloud plan enablement
  - Document security contact configuration
  - Document alert notification setup
  - Document vulnerability assessment deployment
  - Include verification procedures
  - _Requirements: 2.6, 8.1, 8.2, 8.3, 8.4, 8.5_

- [ ] 18. Update control mapping with custom policies
- [ ] 18.1 Update nist-control-mapping.csv with custom policies
  - Add custom SI policies to control mapping
  - Add custom IA policies to control mapping
  - Add custom Guest Configuration policies to control mapping
  - Update implementation status to "Implemented" for custom policies
  - Update enforcement scope and effects
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8_

- [ ] 18.2 Update nist-compliance-coverage.csv with new metrics
  - Recalculate total policies with custom policies included
  - Recalculate enforceable policies count
  - Update enforcement rate percentage
  - Update SI family coverage (should increase significantly)
  - Update IA family coverage
  - Update Guest Configuration coverage
  - _Requirements: 10.1, 10.2, 10.3, 10.4_

- [ ] 19. Create validation and testing procedures
- [ ] 19.1 Create test scripts for custom policies
  - Create PowerShell script to test Defender deployment policy
  - Create PowerShell script to test Guest Configuration deployment
  - Create PowerShell script to validate Entra ID configurations
  - Include expected results and success criteria
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 10.1, 10.2_

- [ ] 19.2 Create compliance validation script
  - Create PowerShell script to check overall NIST compliance
  - Script should check Azure Policy compliance
  - Script should check Defender for Cloud status
  - Script should check Guest Configuration status
  - Script should check Entra ID configurations
  - Generate comprehensive compliance report
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_
