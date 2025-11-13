    CCACCR-78
    AU-2 - Event Logging.
    AU Audit & Account.
    L1 or L2 Common Control Catalog Description -
    a. All modern operating systems can audit the following events:
      1. Authentication events:
      (1) Logons (Success/Failure)
      (2) Logoffs (Success);
      2. File and Objects events:
      (1) Create (Success/Failure)
      (2) Access (Success/Failure)
      (3) Delete (Success/Failure)
      (4) Modify (Success/Failure)
      (5) Permission Modification (Success/Failure)
      (6) Ownership Modification (Success/Failure)
      3. Writes/downloads to external devices/media (e.g., A-Drive, CD/DVD devices/printers) (Success/Failure)
      4. Uploads from external devices (e.g., CD/DVD drives) (Success/Failure)
      5. User and Group Management events:
      (1) User add, delete, modify, suspend, lock (Success/Failure)
      (2) Group/Role add, delete, modify (Success/Failure)
      6. Use of Privileged/Special Rights events:
      (1) Security or audit policy changes (Success/Failure)
      (2) Configuration changes (Success/Failure)
      7. Admin or root-level access (Success/Failure)
      8. Privilege/Role escalation (Success/Failure)
      9. Audit and log data accesses (Success/Failure)
      10. System reboot, restart, and shutdown (Success/Failure)
      11. Print to a device (Success/Failure)
      12. Print to a file (e.g., PDF) (Success/Failure)
      13. Application (e.g., Firefox, Internet Explorer, MS Office Suite, etc.) initialization (Success/Failure)
      14. Export of information (Success/Failure) include (e.g., to CDRW, thumb drives, or remote systems)
      15. Import of information (Success/Failure) include (e.g., from CDRW, thumb drives, or remote systems)
    b. The organization actively coordinates security configurations and tools across relevant entities that require audit-related information.
    c. Audit log events for Windows: 1. (1), 5. (1 – Add, Delete, Modify, Lock), 8 (Success) listed under AU-2 a) are audited weekly.
    d. Through daily incident response, CSIRT validates the adequacy of our logging capabilities for after-the-fact investigations.
    e. The ISSM conducts an annual review and updates event types as needed.

    CSP/Vendor Implementation Details -
    (a) The customer is responsible for identifying organization-defined event types that the system is capable of logging for customer-deployed resources in support of the audit function. Azure services are individually able to generate audit logs that can then be consolidated into a single SIEM, either an Azure service or a customer third party. For guidance on configuring audit logs, please visit - https://learn.microsoft.com/en-us/azure/security/fundamentals/log-audit
    (b) The customer is responsible for coordinating the event logging function with other organizational entities requiring audit-related information to guide and inform the selection criteria for events to be logged. Azure services are individually able to generate audit logs that can then be consolidated into a single SIEM, either an Azure service or a customer third party. For guidance on configuring audit logs, please visit - https://learn.microsoft.com/en-us/azure/security/fundamentals/log-audit
    (c) The customer is responsible for specifying the organization-defined event types (subset of the event types defined in AU-2a) for logging within the system along with the frequency of (or situation requiring) logging for each identified event type for customer-deployed resources. Azure services are individually able to generate audit logs that can then be consolidated into a single SIEM, either an Azure service or a customer third party. For guidance on configuring audit logs, please visit - https://learn.microsoft.com/en-us/azure/security/fundamentals/log-audit
    (d) The customer is responsible for providing a rationale for why the event types selected for logging are deemed to be adequate to support after-the-fact investigations of incidents. Azure services are individually able to generate audit logs that can then be consolidated into a single SIEM, either an Azure service or a customer third party. For guidance on configuring audit logs, please visit - https://learn.microsoft.com/en-us/azure/security/fundamentals/log-audit
    (e) The customer is responsible for reviewing and updating the event types selected for logging at the organization-defined frequency. Azure services are individually able to generate audit logs that can then be consolidated into a single SIEM, either an Azure service or a customer third party. For guidance on configuring audit logs, please visit - https://learn.microsoft.com/en-us/azure/security/fundamentals/log-audit

    NIST Control Description -
    a. Identify the types of events that the system is capable of logging in support of the audit function: [Assignment: organization-defined event types that the system is capable of logging];
    b. Coordinate the event logging function with other organizational entities requiring audit-related information to guide and inform the selection criteria for events to be logged;
    c. Specify the following event types for logging within the system: [Assignment: organization-defined event types (subset of the event types defined in AU-2a.) along with the frequency of (or situation requiring) logging for each identified event type];
    d. Provide a rationale for why the event types selected for logging are deemed to be adequate to support after-the-fact investigations of incidents; and
    e. Review and update the event types selected for logging [Assignment: organization-defined frequency].
    Assignee: Mejia, John
    Issue Type: Task
    Priority: Lowest
     
    (SA/ENG) Configure Environment: Mejia, John swimlane
    (SA/ENG) Provide Implementation Details & Evidence: Mejia, John swimlane
    (ISSO) Verify Implementation Details & Evidence: Mejia, John swimlane
    (SCA) Validate Evidence: Mejia, John swimlane
    (ISSM) Validate Evidence: Mejia, John swimlane
    Quality Assurance: Mejia, John swimlane
    Done: Mejia, John swimlane

Unassigned70 issues

    ID Technical Requirements or Policy: Unassigned swimlane
    CCACCR-37
    AC-5 - Separation of Duties.
    AC Access Control
    None

    CSP/Vendor Implementation Details -
    (a) The customer is responsible for identifying and documenting organization-defined duties of individuals requiring separation for customer-controlled accounts. Azure account management information using Azure Active Directory can be found here - https://learn.microsoft.com/en-us/azure/active-directory/fundamentals/whatis
    (b) The customer is responsible for defining system access authorizations to support separation of duties across customer-controlled accounts. Azure account management information using Azure Active Directory can be found here - https://learn.microsoft.com/en-us/azure/active-directory/fundamentals/whatis

    NIST Control Description -
    a. Identify and document [Assignment: organization-defined duties of individuals requiring separation]; and
    b. Define system access authorizations to support separation of duties.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-38
    AC-6 - Least Privilege.
    AC Access Control
    None

    CSP/Vendor Implementation Details -
    The customer is responsible for employing the principle of least privilege, allowing only authorized accesses for users (or processes acting on behalf of users) that are necessary to accomplish assigned organizational tasks across customer-controlled accounts. This can be configured within Azure Active Directory permissions. Azure account management information using Azure Active Directory can be found here - https://learn.microsoft.com/en-us/azure/active-directory/fundamentals/whatis

    NIST Control Description -
    Employ the principle of least privilege, allowing only authorized accesses for users (or processes acting on behalf of users) that are necessary to accomplish assigned organizational tasks.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-39
    AC-6(1) - Least Privilege | Authorize Access to Security Functions.
    AC Access Control
    None

    CSP/Vendor Implementation Details -
    (a) The customer is responsible for authorizing access for organization-defined individuals or roles to organization-defined security functions (deployed in hardware, software, and firmware). This can be configured within Azure Active Directory permissions. Azure account management information using Azure Active Directory can be found here - https://learn.microsoft.com/en-us/azure/active-directory/fundamentals/whatis
    (b) The customer is responsible for authorizing access for organization-defined individuals or roles to organization-defined security-relevant information. This can be configured within Azure Active Directory permissions. Azure account management information using Azure Active Directory can be found here - https://learn.microsoft.com/en-us/azure/active-directory/fundamentals/whatis

    NIST Control Description -
    Authorize access for [Assignment: organization-defined individuals or roles] to:
    (a) [Assignment: organization-defined security functions (deployed in hardware, software, and firmware)]; and
    (b) [Assignment: organization-defined security-relevant information].
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-42
    AC-6(5) - Least Privilege | Privileged Accounts.
    AC Access Control
    None

    CSP/Vendor Implementation Details -
    The customer is responsible for restricting privileged customer-controlled accounts on the system to the organization-defined personnel or roles. This can be accomplished in Azure Active Directory. Azure account management information using Azure Active Directory can be found here - https://learn.microsoft.com/en-us/azure/active-directory/fundamentals/whatis

    NIST Control Description -
    Restrict privileged accounts on the system to [Assignment: organization-defined personnel or roles].
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-43
    AC-6(7) - Least Privilege | Review of User Privileges.
    AC Access Control
    None

    CSP/Vendor Implementation Details -
    (a) The customer is responsible for reviewing the privileges assigned to organization-defined, customer-controlled roles or classes of users to validate the need for such privileges of customer-controlled accounts at the organization-defined frequency. This can be accomplished in Azure Active Directory. Azure account management information using Azure Active Directory can be found here - https://learn.microsoft.com/en-us/azure/active-directory/fundamentals/whatis
    (b) The customer is responsible for reassigning or removing privileges for customer-controlled accounts, if necessary, to correctly reflect organizational mission and business needs. Azure account management information using Azure Active Directory can be found here - https://learn.microsoft.com/en-us/azure/active-directory/fundamentals/whatis

    NIST Control Description -
    (a) Review [Assignment: organization-defined frequency] the privileges assigned to [Assignment: organization-defined roles or classes of users] to validate the need for such privileges; and
    (b) Reassign or remove privileges, if necessary, to correctly reflect organizational mission and business needs.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-46
    AC-6(10) - Least Privilege | Prohibit Non-privileged Users from Executing Privileged Functions.
    AC Access Control
    None

    CSP/Vendor Implementation Details -
    For customers of IaaS and PaaS services, the customer is responsible for preventing non-privileged users from executing privileged functions on customer-deployed resources. This is traditionally implemented at the operating system level, and would depend on the OS selection by the customer. SaaS customers do not execute software directly within their boundary.

    NIST Control Description -
    Prevent non-privileged users from executing privileged functions.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-61
    AC-18(3) - Wireless Access | Disable Wireless Networking.
    AC Access Control
    None

    CSP/Vendor Implementation Details -
    The customer is fully responsible for wireless within their physical environment.

    NIST Control Description -
    Disable, when not intended for use, wireless networking capabilities embedded within system components prior to issuance and deployment.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-69
    AC-21 - Information Sharing.
    AC Access Control
    None

    CSP/Vendor Implementation Details -
    (a) The customer is responsible for enabling authorized and customer-controlled users to determine whether access authorizations assigned to a sharing partner match the information’s access and use restrictions for organization-defined information sharing circumstances where user discretion is required.
    (b) The customer is responsible for employing organization-defined automated mechanisms or manual processes to assist customer users with making information sharing decisions.

    NIST Control Description -
    a. Enable authorized users to determine whether access authorizations assigned to a sharing partner match the information’s access and use restrictions for [Assignment: organization-defined information sharing circumstances where user discretion is required]; and
    b. Employ [Assignment: organization-defined automated mechanisms or manual processes] to assist users in making information sharing and collaboration decisions.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-106
    CA-3 - Information Exchange.
    CA Assess., Auth., and Monitoring
    L1 or L2 Common Control Catalog Description -
    NA - No interconnections with external environments. Cloud services have existing ATOs.

    CSP/Vendor Implementation Details -
    (a) The customer is responsible for approving and managing the exchange of information between the system and other systems using interconnection security agreements; information exchange security agreements; memoranda of understanding or agreement; service level agreements; user agreements; nondisclosure agreements; or another organization-defined type of agreement. Azure networking information can be found here - https://learn.microsoft.com/en-us/azure/networking/fundamentals/networking-overview
    (b) The customer is responsible for documenting as part of each exchange agreement, the interface characteristics, security and privacy requirements, controls, and responsibilities for each system, and the impact level of the information communicated. Azure networking information can be found here - https://learn.microsoft.com/en-us/azure/networking/fundamentals/networking-overview
    (c) The customer is responsible for reviewing and updating the agreements at the organization-defined frequency. Azure networking information can be found here - https://learn.microsoft.com/en-us/azure/networking/fundamentals/networking-overview

    NIST Control Description -
    a. Approve and manage the exchange of information between the system and other systems using [Selection (one or more): interconnection security agreements; information exchange security agreements; memoranda of understanding or agreement; service level agreements; user agreements; nondisclosure agreements; [Assignment: organization-defined type of agreement]];
    b. Document, as part of each exchange agreement, the interface characteristics, security and privacy requirements, controls, and responsibilities for each system, and the impact level of the information communicated; and
    c. Review and update the agreements [Assignment: organization-defined frequency].
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-118
    CM-2 - Baseline Configuration.
    CM Config. Management
    None

    CSP/Vendor Implementation Details -
    (a) The customer is responsible for developing, documenting, and maintaining under configuration control, a current baseline configuration of the customer-deployed resources and services. Azure services can be configured to meet multiple baseline configuration regimes. Information can be found here, but service-specific configuration information can be found on the Azure website for each service as well - https://learn.microsoft.com/en-us/security/benchmark/azure/security-baselines-overview
    (b) The customer is responsible for reviewing and updating the baseline configuration of the system at an organization-defined frequency; when required due to organization-defined circumstances; and when system components are installed or upgraded. Azure services can be configured to meet multiple baseline configuration regimes. Information can be found here, but service-specific configuration information can be found on the Azure website for each service as well - https://learn.microsoft.com/en-us/security/benchmark/azure/security-baselines-overview

    NIST Control Description -
    a. Develop, document, and maintain under configuration control, a current baseline configuration of the system; and
    b. Review and update the baseline configuration of the system:
    1. [Assignment: organization-defined frequency];
    2. When required due to [Assignment: organization-defined circumstances]; and
    3. When system components are installed or upgraded.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-143
    CM-8(3) - System Component Inventory | Automated Unauthorized Component Detection.
    CM Config. Management
    L1 or L2 Common Control Catalog Description -
    (a) The information system employs device registration, endpoint security, and vulnerability scanning tools to detect the unauthorized components/devices. If software is determined to be unauthorized, the automated tools can scan for, and block systems containing that software.
    (b) If required, the information system possesses the capability to block network access, prevent unauthorized functions from running, and notify the relevant personnel.

    CSP/Vendor Implementation Details -
    (a) The customer is responsible for employing organization-defined automated mechanisms to detect the presence of unauthorized hardware, software, and firmware components within customer-deployed resources at the organization-defined frequency. Azure customers are able to manage their inventory in a number of ways - https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/manage/azure-management-guide/inventory. In addition, customers may identify unapproved Azure services in using application management - https://learn.microsoft.com/en-us/azure/active-directory/manage-apps/view-applications-portal
    (b) The customer is responsible for taking the following actions when unauthorized components are detected: disable network access by such components; isolate the components; or notify organization-defined personnel or roles. Azure customers are able to manage their inventory in a number of ways - https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/manage/azure-management-guide/inventory. In addition, customers may identify unapproved Azure services in using application management - https://learn.microsoft.com/en-us/azure/active-directory/manage-apps/view-applications-portal

    NIST Control Description -
    (a) Detect the presence of unauthorized hardware, software, and firmware components within the system using [Assignment: organization-defined automated mechanisms] [Assignment: organization-defined frequency]; and
    (b) Take the following actions when unauthorized components are detected: [Selection (one or more): disable network access by such components; isolate the components; notify [Assignment: organization-defined personnel or roles]].
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-136
    CM-7 - Least Functionality.
    CM Config. Management
    L1 or L2 Common Control Catalog Description -
    a. The information system enforces the least privilege principle by employing various account types and roles. This ensures that users have the minimum access necessary for their specific duties.
    b. The information system utilizes Access Control Lists (ACLs) on routers and firewalls to effectively prohibit or restrict the use of functions, ports, protocols, and/or services.

    CSP/Vendor Implementation Details -
    (a) The customer is responsible for configuring customer-deployed resources to only provide essential capabilities (e.g., disabling extraneous services that may be provided by default, using a system for a single function rather than a system supporting multiple functions). Azure services are individually able to generate audit logs that can then be consolidated into a single SIEM, either an Azure service or a customer third party. For guidance on configuring audit logs, please visit - https://learn.microsoft.com/en-us/azure/security/fundamentals/log-audit
    (b) The customer is responsible for prohibiting or restricting the use of organization-defined specific functions, ports, protocols, and/or services to provide least functionality. Azure services are individually able to generate audit logs that can then be consolidated into a single SIEM, either an Azure service or a customer third party. For guidance on configuring audit logs, please visit - https://learn.microsoft.com/en-us/azure/security/fundamentals/log-audit

    NIST Control Description -
    a. Configure the system to provide only [Assignment: organization-defined mission essential capabilities]; and
    b. Prohibit or restrict the use of the following functions, ports, protocols, software, and/or services: [Assignment: organization-defined prohibited or restricted functions, system ports, protocols, software, and/or services].
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-119
    CM-2(2) - Baseline Configuration | Automation Support for Accuracy and Currency.
    CM Config. Management
    None

    CSP/Vendor Implementation Details -
    The customer is responsible for employing automated mechanisms to maintain the currency, completeness, accuracy, and availability of the baseline configuration of customer-deployed resources using organization-defined automated mechanisms. Azure services can be configured to meet multiple baseline configuration regimes. Information can be found here, but service-specific configuration information can be found on the Azure website for each service as well - https://learn.microsoft.com/en-us/security/benchmark/azure/security-baselines-overview

    NIST Control Description -
    Maintain the currency, completeness, accuracy, and availability of the baseline configuration of the system using [Assignment: organization-defined automated mechanisms].
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-120
    CM-2(3) - Baseline Configuration | Retention of Previous Configurations.
    CM Config. Management
    None

    CSP/Vendor Implementation Details -
    The customer is responsible for retaining previous versions of baseline configurations for customer-deployed resources to support rollback. Azure services can be configured to meet multiple baseline configuration regimes. Information can be found here, but service-specific configuration information can be found on the Azure website for each service as well - https://learn.microsoft.com/en-us/security/benchmark/azure/security-baselines-overview

    NIST Control Description -
    Retain [Assignment: organization-defined number] of previous versions of baseline configurations of the system to support rollback.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-124
    CM-3(2) - Configuration Change Control | Testing, Validation, and Documentation of Changes.
    CM Config. Management
    None

    CSP/Vendor Implementation Details -
    The customer is responsible for testing, validating, and documenting changes to customer-deployed resources before implementation.

    NIST Control Description -
    Test, validate, and document changes to the system before finalizing the implementation of the changes.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-127
    CM-4 - Impact Analyses.
    CM Config. Management
    None

    CSP/Vendor Implementation Details -
    The customer is responsible for analyzing changes to customer-deployed resources to determine potential security and privacy impacts prior to change implementation.

    NIST Control Description -
    Analyze changes to the system to determine potential security and privacy impacts prior to change implementation.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-129
    CM-4(2) - Impact Analyses | Verification of Controls.
    CM Config. Management
    None

    CSP/Vendor Implementation Details -
    The customer is responsible for, after system changes, verifying that the impacted controls are implemented correctly, operating as intended, and producing the desired outcome with regard to meeting the security and privacy requirements for the system.

    NIST Control Description -
    After system changes, verify that the impacted controls are implemented correctly, operating as intended, and producing the desired outcome with regard to meeting the security and privacy requirements for the system.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-130
    CM-5 - Access Restrictions for Change.
    CM Config. Management
    None

    CSP/Vendor Implementation Details -
    The customer is responsible for defining, documenting, approving, and enforcing logical access restrictions associated with changes to the customer-deployed resources. Physical changes are handled entirely by Microsoft. Azure account management information using Azure Active Directory can be found here - https://learn.microsoft.com/en-us/azure/active-directory/fundamentals/whatis

    NIST Control Description -
    Define, document, approve, and enforce physical and logical access restrictions associated with changes to the system.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-139
    CM-7(5) - Least Functionality | Authorized Software — Allow-by-exception.
    CM Config. Management
    None

    CSP/Vendor Implementation Details -
    (a) For customers of IaaS and PaaS services, the customer is responsible for identifying software programs authorized to execute on customer-deployed resources. This is traditionally implemented at the operating system level, and would depend on the OS selection by the customer. SaaS customers do not execute software directly within their boundary.
    (b) For customers of IaaS and PaaS services, the customer is responsible for employing a deny-all, permit-by-exception policy to allow the execution of authorized software programs on customer-deployed resources. This is traditionally implemented at the operating system level, and would depend on the OS selection by the customer. SaaS customers do not execute software directly within their boundary.
    (c) For customers of IaaS and PaaS services, the customer is responsible for reviewing and updating the list of authorized software programs at the organization-defined frequency. This is traditionally implemented at the operating system level, and would depend on the OS selection by the customer. SaaS customers do not execute software directly within their boundary.

    NIST Control Description -
    (a) Identify [Assignment: organization-defined software programs authorized to execute on the system];
    (b) Employ a deny-all, permit-by-exception policy to allow the execution of authorized software programs on the system; and
    (c) Review and update the list of authorized software programs [Assignment: organization-defined frequency].
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-140
    CM-8 - System Component Inventory.
    CM Config. Management
    None

    CSP/Vendor Implementation Details -
    (a) The customer is responsible for developing and documenting an inventory of customer-deployed resources that accurately reflects the system; includes all components within the system; does not include duplicate accounting of components or components assigned to any other system; is at the level of granularity deemed necessary for tracking and reporting; and includes the organization-defined information to achieve system component accountability. Azure customers are able to manage their inventory in a number of ways - https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/manage/azure-management-guide/inventory
    (b) The customer is responsible for reviewing and updating the inventory defined in CM-08.a at the organization-defined frequency. Azure customers are able to manage their inventory in a number of ways - https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/manage/azure-management-guide/inventory

    NIST Control Description -
    a. Develop and document an inventory of system components that:
    1. Accurately reflects the system;
    2. Includes all components within the system;
    3. Does not include duplicate accounting of components or components assigned to any other system;
    4. Is at the level of granularity deemed necessary for tracking and reporting; and
    5. Includes the following information to achieve system component accountability: [Assignment: organization-defined information deemed necessary to achieve effective system component accountability]; and
    b. Review and update the system component inventory [Assignment: organization-defined frequency].
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-141
    CM-8(1) - System Component Inventory | Updates During Installation and Removal.
    CM Config. Management
    None

    CSP/Vendor Implementation Details -
    The customer is responsible for reviewing and updating the inventory of customer-deployed resources when installations, removals, and system updates occur. Azure customers are able to manage their inventory in a number of ways - https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/manage/azure-management-guide/inventory

    NIST Control Description -
    Update the inventory of system components as part of component installations, removals, and system updates.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-145
    CM-9 - Configuration Management Plan.
    CM Config. Management
    None

    CSP/Vendor Implementation Details -
    (a) The customer is responsible for developing, documenting, and implementing a configuration management plan that addresses roles, responsibilities, and configuration management processes and procedures.
    (b) The customer is responsible for developing, documenting, and implementing a configuration management plan that establishes a process for identifying configuration items throughout the system development life cycle and for managing the configuration of customer-deployed resources.
    (c) The customer is responsible for developing, documenting, and implementing a configuration management plan that defines the configuration items for the customer-deployed resources and places the configuration items under configuration management.
    (d) The customer is responsible for developing, documenting, and implementing a configuration management plan that is reviewed and approved by organization-defined personnel or roles.
    (e) The customer is responsible for developing, documenting, and implementing a configuration management plan that protects the configuration management plan from unauthorized disclosure and modification.

    NIST Control Description -
    Develop, document, and implement a configuration management plan for the system that:
    a. Addresses roles, responsibilities, and configuration management processes and procedures;
    b. Establishes a process for identifying configuration items throughout the system development life cycle and for managing the configuration of the configuration items;
    c. Defines the configuration items for the system and places the configuration items under configuration management;
    d. Is reviewed and approved by [Assignment: organization-defined personnel or roles]; and
    e. Protects the configuration management plan from unauthorized disclosure and modification.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-148
    CM-12 - Information Location.
    CM Config. Management
    None

    CSP/Vendor Implementation Details -
    (a) The customer is responsible for identifying and documenting the location of organization-defined information and the specific system components on which the information is processed. Azure customers are able to deploy to their desired regions - https://azure.microsoft.com/en-us/explore/global-infrastructure/geographies/
    (b) The customer is responsible for identifying and documenting the users who have access to the system and system components where the information is processed and stored. Azure customers are able to deploy to their desired regions - https://azure.microsoft.com/en-us/explore/global-infrastructure/geographies/
    (c) The customer is responsible for documenting changes to the location (i.e., system or system components) where the information is processed and stored. Azure customers are able to deploy to their desired regions - https://azure.microsoft.com/en-us/explore/global-infrastructure/geographies/

    NIST Control Description -
    a. Identify and document the location of [Assignment: organization-defined information] and the specific system components on which the information is processed and stored;
    b. Identify and document the users who have access to the system and system components where the information is processed and stored; and
    c. Document changes to the location (i.e., system or system components) where the information is processed and stored.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-149
    CM-12(1) - Information Location | Automated Tools to Support Information Location.
    CM Config. Management
    None

    CSP/Vendor Implementation Details -
    The customer is responsible for using automated tools to identify organization-defined information by information type on organization-defined system components to ensure controls are in place to protect organizational information and individual privacy. Azure customers are able to deploy to their desired regions - https://azure.microsoft.com/en-us/explore/global-infrastructure/geographies/

    NIST Control Description -
    Use automated tools to identify [Assignment: organization-defined information by information type] on [Assignment: organization-defined system components] to ensure controls are in place to protect organizational information and individual privacy.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-152
    CP-2 - Contingency Plan.
    CP Contingency Plan.
    None

    CSP/Vendor Implementation Details -
    (a) For customers of IaaS and PaaS services, the customer is responsible for developing a contingency plan for customer-deployed resources that identifies essential mission and business functions and associated contingency requirements; provides recovery objectives, restoration priorities, and metrics; addresses contingency roles, responsibilities, assigned individuals with contact information; addresses maintaining essential mission and business functions despite a system disruption, compromise, or failure; addresses eventual, full system restoration without deterioration of the controls originally planned and implemented; addresses the sharing of contingency information; and is reviewed and approved by organization-defined personnel or roles. Note: the customer should also include any reliance on Azure functionality to perform these tasks.
    (b) For customers of IaaS and PaaS services, the customer is responsible for distributing the contingency plans to organization-defined key contingency personnel (identified by name and/or by role) and organizational elements.
    (c) For customers of IaaS and PaaS services, the customer is responsible for coordinating contingency planning with incident handling.
    (d) For customers of IaaS and PaaS services, the customer is responsible for reviewing the contingency plan at the organization-defined frequency.
    (e) For customers of IaaS and PaaS services, the customer is responsible for updating the contingency plan and how those updates reflect changes to the organization, resources, or environment of operation; and the problems encountered during implementation, execution, or testing of contingency activities.
    (f) For customers of IaaS and PaaS services, the customer is responsible for communicating changes made to the contingency plan to organization-defined key contingency personnel (identified by name and/or by role) and organizational elements.
    (g) For customers of IaaS and PaaS services, the customer is responsible for incorporating lessons learned from contingency plan testing, training, or actual contingency activities into contingency testing and training.
    (h) For customers of IaaS and PaaS services, the customer is responsible for protecting the contingency plan to prevent unauthorized disclosure or modification of the plan.

    NIST Control Description -
    a. Develop a contingency plan for the system that:
    1. Identifies essential mission and business functions and associated contingency requirements;
    2. Provides recovery objectives, restoration priorities, and metrics;
    3. Addresses contingency roles, responsibilities, assigned individuals with contact information;
    4. Addresses maintaining essential mission and business functions despite a system disruption, compromise, or failure;
    5. Addresses eventual, full system restoration without deterioration of the controls originally planned and implemented;
    6. Addresses the sharing of contingency information; and
    7. Is reviewed and approved by [Assignment: organization-defined personnel or roles];
    b. Distribute copies of the contingency plan to [Assignment: organization-defined key contingency personnel (identified by name and/or by role) and organizational elements];
    c. Coordinate contingency planning activities with incident handling activities;
    d. Review the contingency plan for the system [Assignment: organization-defined frequency];
    e. Update the contingency plan to address changes to the organization, system, or environment of operation and problems encountered during contingency plan implementation, execution, or testing;
    f. Communicate contingency plan changes to [Assignment: organization-defined key contingency personnel (identified by name and/or by role) and organizational elements];
    g. Incorporate lessons learned from contingency plan testing, training, or actual contingency activities into contingency testing and training; and
    h. Protect the contingency plan from unauthorized disclosure and modification.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-155
    CP-2(3) - Contingency Plan | Resume Mission and Business Functions.
    CP Contingency Plan.
    None

    CSP/Vendor Implementation Details -
    For customers of IaaS and PaaS services, the customer is responsible for resuming essential mission and business functions within the organization-defined time period of contingency plan activation. Note: if the customer configures Azure appropriately for reserving processing capacity in an alternate region, Azure can support continued system operation during contingency activities. Additional information can be found here - https://learn.microsoft.com/en-us/azure/virtual-machines/capacity-reservation-overview

    NIST Control Description -
    Plan for the resumption of [Selection: all; essential] mission and business functions within [Assignment: organization-defined time period] of contingency plan activation.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-157
    CP-2(8) - Contingency Plan | Identify Critical Assets.
    CP Contingency Plan.
    None

    CSP/Vendor Implementation Details -
    For customers of IaaS and PaaS services, the customer is responsible for identifying critical customer-deployed resources supporting essential mission and business functions.

    NIST Control Description -
    Identify critical system assets supporting [Selection: all; essential] mission and business functions.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-160
    CP-4 - Contingency Plan Testing.
    CP Contingency Plan.
    None

    CSP/Vendor Implementation Details -
    (a) For customers of IaaS and PaaS services, the customer is responsible for testing the contingency plan for the customer-deployed resources at the organization-defined frequency using the organization-defined tests to determine the effectiveness of the plan and the readiness to execute the plan. Azure business continuity testing information can be found here - https://learn.microsoft.com/en-us/azure/reliability/business-continuity-management-program
    (b) For customers of IaaS and PaaS services, the customer is responsible for reviewing the results of contingency plan testing (see CP-04.a). Azure business continuity testing information can be found here - https://learn.microsoft.com/en-us/azure/reliability/business-continuity-management-program
    (c) For customers of IaaS and PaaS services, the customer is responsible for initiating corrective action regarding contingency plan testing. Azure business continuity testing information can be found here - https://learn.microsoft.com/en-us/azure/reliability/business-continuity-management-program

    NIST Control Description -
    a. Test the contingency plan for the system [Assignment: organization-defined frequency] using the following tests to determine the effectiveness of the plan and the readiness to execute the plan: [Assignment: organization-defined tests].
    b. Review the contingency plan test results; and
    c. Initiate corrective actions, if needed.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-161
    CP-4(1) - Contingency Plan Testing | Coordinate with Related Plans.
    CP Contingency Plan.
    None

    CSP/Vendor Implementation Details -
    For customers of IaaS and PaaS services, the customer is responsible for coordinating contingency plan testing with the testing of related plans (e.g., business continuity, disaster recovery). Azure business continuity testing information can be found here - https://learn.microsoft.com/en-us/azure/reliability/business-continuity-management-program

    NIST Control Description -
    Coordinate contingency plan testing with organizational elements responsible for related plans.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-163
    CP-6 - Alternate Storage Site.
    CP Contingency Plan.
    None

    CSP/Vendor Implementation Details -
    (a) For customers of IaaS and PaaS services, the customer is responsible for establishing an alternate storage site with the ability to store and retrieve backup information, and the agreements permitting such activities. Note: if the customer configures Azure appropriately for reserving storage capacity in an alternate region, Azure can support the secure storage and retrieval of system data. Azure customers are able to deploy to their desired regions - https://azure.microsoft.com/en-us/explore/global-infrastructure/geographies/
    (b) For customers of IaaS and PaaS services, the customer is responsible for establishing an alternate storage site with equivalent security safeguards as the primary site. Note: if the customer configures Azure appropriately for reserving storage capacity in an alternate region, Azure can support the secure storage and retrieval of system data. Azure customers are able to deploy to their desired regions - https://azure.microsoft.com/en-us/explore/global-infrastructure/geographies/

    NIST Control Description -
    a. Establish an alternate storage site, including necessary agreements to permit the storage and retrieval of system backup information; and
    b. Ensure that the alternate storage site provides controls equivalent to that of the primary site.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-164
    CP-6(1) - Alternate Storage Site | Separation from Primary Site.
    CP Contingency Plan.
    None

    CSP/Vendor Implementation Details -
    For customers of IaaS and PaaS services, the customer is responsible for establishing an alternate storage site that is separate from the primary storage site to reduce its susceptibility to the same threats (e.g., natural disasters). Note: if the customer configures Azure appropriately for reserving storage capacity in an alternate region, Azure can support the secure storage and retrieval of system data. Azure customers are able to deploy to their desired regions - https://azure.microsoft.com/en-us/explore/global-infrastructure/geographies/

    NIST Control Description -
    Identify an alternate storage site that is sufficiently separated from the primary storage site to reduce susceptibility to the same threats.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-166
    CP-6(3) - Alternate Storage Site | Accessibility.
    CP Contingency Plan.
    None

    CSP/Vendor Implementation Details -
    For customers of IaaS and PaaS services, the customer is responsible for identifying potential accessibility problems to the alternate storage site in the event of an area-wide disruption or disaster and outline explicit mitigation actions. Note: if the customer configures Azure appropriately for reserving storage capacity in an alternate region, Azure can support the secure storage and retrieval of system data. Azure customers are able to deploy to their desired regions - https://azure.microsoft.com/en-us/explore/global-infrastructure/geographies/

    NIST Control Description -
    Identify potential accessibility problems to the alternate storage site in the event of an area-wide disruption or disaster and outline explicit mitigation actions.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-167
    CP-7 - Alternate Processing Site.
    CP Contingency Plan.
    None

    CSP/Vendor Implementation Details -
    (a) For customers of IaaS and PaaS services, the customer is responsible for an alternate processing site, including necessary agreements to permit the transfer and resumption of organization-defined system operations for essential mission and business functions within the organization-defined time period consistent with recovery time and recovery point objectives when the primary processing capabilities are unavailable. Note: if the customer configures Azure appropriately for reserving processing capacity in an alternate region, Azure can support the continuation of secure system operation. Azure customers are able to deploy to their desired regions - https://azure.microsoft.com/en-us/explore/global-infrastructure/geographies/
    (b) For customers of IaaS and PaaS services, the customer is responsible for making available at the alternate processing site, the equipment and supplies required to transfer and resume operations or put contracts in place to support delivery to the site within the organization-defined time period for transfer and resumption. Note: if the customer configures Azure appropriately for reserving processing capacity in an alternate region, Azure can support the continuation of secure system operation. Azure customers are able to deploy to their desired regions - https://azure.microsoft.com/en-us/explore/global-infrastructure/geographies/
    (c) For customers of IaaS and PaaS services, the customer is responsible for establishing an alternate processing site that has security safeguards equivalent to the primary site. Note: if the customer configures Azure appropriately for reserving processing capacity in an alternate region, Azure can support the continuation of secure system operation. Azure customers are able to deploy to their desired regions - https://azure.microsoft.com/en-us/explore/global-infrastructure/geographies/

    NIST Control Description -
    a. Establish an alternate processing site, including necessary agreements to permit the transfer and resumption of [Assignment: organization-defined system operations] for essential mission and business functions within [Assignment: organization-defined time period consistent with recovery time and recovery point objectives] when the primary processing capabilities are unavailable;
    b. Make available at the alternate processing site, the equipment and supplies required to transfer and resume operations or put contracts in place to support delivery to the site within the organization-defined time period for transfer and resumption; and
    c. Provide controls at the alternate processing site that are equivalent to those at the primary site.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-168
    CP-7(1) - Alternate Processing Site | Separation from Primary Site.
    CP Contingency Plan.
    None

    CSP/Vendor Implementation Details -
    For customers of IaaS and PaaS services, the customer is responsible for establishing an alternative processing site that is separate from the primary processing site to reduce its susceptibility to the same threats (e.g., natural disasters). Note: if the customer configures Azure appropriately for reserving processing capacity in an alternate region, Azure can support the continuation of secure system operation. Azure customers are able to deploy to their desired regions - https://azure.microsoft.com/en-us/explore/global-infrastructure/geographies/

    NIST Control Description -
    Identify an alternate processing site that is sufficiently separated from the primary processing site to reduce susceptibility to the same threats.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-169
    CP-7(2) - Alternate Processing Site | Accessibility.
    CP Contingency Plan.
    None

    CSP/Vendor Implementation Details -
    For customers of IaaS and PaaS services, the customer is responsible for identifying potential accessibility problems to alternate processing sites in the event of an area-wide disruption or disaster and outlines explicit mitigation actions. Note: if the customer configures Azure appropriately for reserving processing capacity in an alternate region, Azure can support the continuation of secure system operation. Azure customers are able to deploy to their desired regions - https://azure.microsoft.com/en-us/explore/global-infrastructure/geographies/

    NIST Control Description -
    Identify potential accessibility problems to alternate processing sites in the event of an area-wide disruption or disaster and outlines explicit mitigation actions.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-170
    CP-7(3) - Alternate Processing Site | Priority of Service.
    CP Contingency Plan.
    None

    CSP/Vendor Implementation Details -
    For customers of IaaS and PaaS services, the customer is responsible for establishing alternate processing site agreements containing priority-of-service provisions which correspond with customer-defined availability requirements (e.g., RTO's). Note: if the customer configures Azure appropriately for reserving processing capacity in an alternate region, Azure can support the continuation of secure system operation. Azure customers are able to deploy to their desired regions - https://azure.microsoft.com/en-us/explore/global-infrastructure/geographies/

    NIST Control Description -
    Develop alternate processing site agreements that contain priority-of-service provisions in accordance with availability requirements (including recovery time objectives).
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-172
    CP-9 - System Backup.
    CP Contingency Plan.
    None

    CSP/Vendor Implementation Details -
    (a) For customers of IaaS and PaaS services, the customer is responsible for conducting backups of user-level information in customer-deployed resources at a frequency consistent with customer-defined RTO's and RPO's. Note: if the customer configures Azure backup services appropriately, Azure can support data loss prevention. Azure customers can utilize the Azure Backup service to streamline this process. https://learn.microsoft.com/en-us/azure/backup/backup-overview
    (b) For customers of IaaS and PaaS services, the customer is responsible for conducting backups of system-level information in customer-deployed resources at a frequency consistent with customer-defined RTO's and RPO's. Note: if the customer configures Azure backup services appropriately, Azure can support data loss prevention. Azure customers can utilize the Azure Backup service to streamline this process. https://learn.microsoft.com/en-us/azure/backup/backup-overview
    (c) For customers of IaaS and PaaS services, the customer is responsible for conducting backups of system documentation information, including security- and privacy-related documentation, in customer-deployed resources at a frequency consistent with customer-defined RTO's and RPO's. Note: if the customer configures Azure backup services appropriately, Azure can support data loss prevention. Azure customers can utilize the Azure Backup service to streamline this process. https://learn.microsoft.com/en-us/azure/backup/backup-overview
    (d) For customers of IaaS and PaaS services, the customer is responsible for protecting the confidentiality, integrity, and availability (CIA) of customer-controlled backup data. Note: if the customer configures Azure backup services appropriately, Azure can support the protection of backup data. Azure customers can utilize the Azure Backup service to streamline this process. https://learn.microsoft.com/en-us/azure/backup/backup-overview

    NIST Control Description -
    a. Conduct backups of user-level information contained in [Assignment: organization-defined system components] [Assignment: organization-defined frequency consistent with recovery time and recovery point objectives];
    b. Conduct backups of system-level information contained in the system [Assignment: organization-defined frequency consistent with recovery time and recovery point objectives];
    c. Conduct backups of system documentation, including security- and privacy-related documentation [Assignment: organization-defined frequency consistent with recovery time and recovery point objectives]; and
    d. Protect the confidentiality, integrity, and availability of backup information.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-173
    CP-9(1) - System Backup | Testing for Reliability and Integrity.
    CP Contingency Plan.
    None

    CSP/Vendor Implementation Details -
    For customers of IaaS and PaaS services, the customer is responsible for backing up customer data and applications. The customer is also responsible for testing those backups at the organization-defined frequency. Azure customers can utilize the Azure Backup service to streamline this process. https://learn.microsoft.com/en-us/azure/backup/backup-overview

    NIST Control Description -
    Test backup information [Assignment: organization-defined frequency] to verify media reliability and information integrity.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-177
    CP-9(8) - System Backup | Cryptographic Protection.
    CP Contingency Plan.
    None

    CSP/Vendor Implementation Details -
    For customers of IaaS and PaaS services, the customer is responsible for implementing cryptographic mechanisms to prevent unauthorized disclosure and modification of organization-defined backup information. Azure customers can utilize the Azure Backup service to streamline this process. https://learn.microsoft.com/en-us/azure/backup/backup-overview

    NIST Control Description -
    Implement cryptographic mechanisms to prevent unauthorized disclosure and modification of [Assignment: organization-defined backup information].
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-178
    CP-10 - System Recovery and Reconstitution.
    CP Contingency Plan.
    None

    CSP/Vendor Implementation Details -
    For customers of IaaS and PaaS services, the customer is responsible for providing for the recovery and reconstitution of customer-deployed resources to a known state within the organization-defined time period consistent with recovery time and recovery point objectives after a disruption, compromise, or failure. Note: if the customer configures Azure backup and/or alternate site processing services appropriately, Azure can support the continued operation of customer-deployed resources. Azure business continuity testing information can be found here - https://learn.microsoft.com/en-us/azure/reliability/business-continuity-management-program

    NIST Control Description -
    Provide for the recovery and reconstitution of the system to a known state within [Assignment: organization-defined time period consistent with recovery time and recovery point objectives] after a disruption, compromise, or failure.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-179
    CP-10(2) - System Recovery and Reconstitution | Transaction Recovery.
    CP Contingency Plan.
    None

    CSP/Vendor Implementation Details -
    For customers of IaaS and PaaS services, the customer is responsible for implementing transaction-based (e.g., transaction rollback, transaction journaling) recovery within customer-deployed resources. Note: if the customer configures Azure backup and/or alternate site processing services appropriately, Azure can support the continued operation of customer-deployed resources. Azure business continuity testing information can be found here - https://learn.microsoft.com/en-us/azure/reliability/business-continuity-management-program

    NIST Control Description -
    Implement transaction recovery for systems that are transaction-based.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-208
    IA-12(5) - Identity Proofing | Address Confirmation.
    IA Id. and Authentication
    None

    CSP/Vendor Implementation Details -
    The customer is responsible for requiring that either registration code or notice of proofing be delivered through an out-of-band channel to verify the users address (physical or digital) of record. Azure account management information using Azure Active Directory can be found here - https://learn.microsoft.com/en-us/azure/active-directory/fundamentals/whatis

    NIST Control Description -
    Require that a [Selection: registration code; notice of proofing] be delivered through an out-of-band channel to verify the users address (physical or digital) of record.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-238
    PL-4 - Rules of Behavior.
    PL Planning
    None

    CSP/Vendor Implementation Details -
    (a) The customer is responsible for establishing and providing to individuals requiring access to the system, the rules that describe their responsibilities and expected behavior for information and system usage, security, and privacy.
    (b) The customer is responsible for receiving a documented acknowledgment from such individuals, indicating that they have read, understand, and agree to abide by the rules of behavior, before authorizing access to information and the system.
    (c) The customer is responsible for reviewing and updating the rules of behavior at the organization-defined frequency.
    (d) The customer is responsible for requiring individuals who have acknowledged a previous version of the rules of behavior to read and re-acknowledge either at the organization-defined frequency or when the rules are revised or updated.

    NIST Control Description -
    a. Establish and provide to individuals requiring access to the system, the rules that describe their responsibilities and expected behavior for information and system usage, security, and privacy;
    b. Receive a documented acknowledgment from such individuals, indicating that they have read, understand, and agree to abide by the rules of behavior, before authorizing access to information and the system;
    c. Review and update the rules of behavior [Assignment: organization-defined frequency]; and
    d. Require individuals who have acknowledged a previous version of the rules of behavior to read and re-acknowledge [Selection (one or more): [Assignment: organization-defined frequency]; when the rules are revised or updated].
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-241
    PL-10 - Baseline Selection.
    PL Planning
    None

    CSP/Vendor Implementation Details -
    The customer is responsible for selecting a control baseline for the system.

    NIST Control Description -
    Select a control baseline for the system.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-242
    PL-11 - Baseline Tailoring.
    PL Planning
    None

    CSP/Vendor Implementation Details -
    The customer is responsible for tailoring the selected control baseline by applying specified tailoring actions.

    NIST Control Description -
    Tailor the selected control baseline by applying specified tailoring actions.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-253
    PS-9 - Position Descriptions.
    PS Personnel Security
    None

    CSP/Vendor Implementation Details -
    The customer is responsible for incorporating security and privacy roles and responsibilities into organizational position descriptions.

    NIST Control Description -
    Incorporate security and privacy roles and responsibilities into organizational position descriptions.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-256
    RA-3 - Risk Assessment.
    RA Risk Assessment
    None

    CSP/Vendor Implementation Details -
    (a) The customer is responsible for conducting a risk assessment including identifying threats to and vulnerabilities in the system; determining the likelihood and magnitude of harm from unauthorized access, use, disclosure, disruption, modification, or destruction of the system, the information it processes, stores, or transmits, and any related information; and determining the likelihood and impact of adverse effects on individuals arising from the processing of personally identifiable information.
    (b) The customer is responsible for conducting a risk assessment including integrating risk assessment results and risk management decisions from the organization and mission or business process perspectives with system-level risk assessments.
    (c) The customer is responsible for conducting a risk assessment including documenting risk assessment results in security and privacy plans or the risk assessment report.
    (d) The customer is responsible for conducting a risk assessment including reviewing risk assessment results at the organization-defined frequency..
    (e) The customer is responsible for conducting a risk assessment including disseminating risk assessment results to organization-defined personnel or roles.
    (f) The customer is responsible for updating the risk assessment at an organization-defined frequency or when there are significant changes to the system, its environment of operation, or other conditions that may impact the security or privacy state of the system.

    NIST Control Description -
    a. Conduct a risk assessment, including:
    1. Identifying threats to and vulnerabilities in the system;
    2. Determining the likelihood and magnitude of harm from unauthorized access, use, disclosure, disruption, modification, or destruction of the system, the information it processes, stores, or transmits, and any related information; and
    3. Determining the likelihood and impact of adverse effects on individuals arising from the processing of personally identifiable information;
    b. Integrate risk assessment results and risk management decisions from the organization and mission or business process perspectives with system-level risk assessments;
    c. Document risk assessment results in [Selection: security and privacy plans; risk assessment report; [Assignment: organization-defined document]];
    d. Review risk assessment results [Assignment: organization-defined frequency];
    e. Disseminate risk assessment results to [Assignment: organization-defined personnel or roles]; and
    f. Update the risk assessment [Assignment: organization-defined frequency] or when there are significant changes to the system, its environment of operation, or other conditions that may impact the security or privacy state of the system.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-264
    RA-5(11) - Vulnerability Monitoring and Scanning | Public Disclosure Program.
    RA Risk Assessment
    None

    CSP/Vendor Implementation Details -
    The customer is responsible for establishing a public reporting channel for receiving reports of vulnerabilities in organizational systems and system components. Customers are able to leverage Defender for Cloud to achieve this - https://learn.microsoft.com/en-us/azure/defender-for-cloud/deploy-vulnerability-assessment-vm

    NIST Control Description -
    Establish a public reporting channel for receiving reports of vulnerabilities in organizational systems and system components.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-265
    RA-7 - Risk Response.
    RA Risk Assessment
    None

    CSP/Vendor Implementation Details -
    The customer is responsible for responding to findings from security and privacy assessments, monitoring, and audits in accordance with organizational risk tolerance.

    NIST Control Description -
    Respond to findings from security and privacy assessments, monitoring, and audits in accordance with organizational risk tolerance.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-266
    RA-9 - Criticality Analysis.
    RA Risk Assessment
    None

    CSP/Vendor Implementation Details -
    The customer is responsible for identifying critical system components and functions by performing a criticality analysis for organization-defined systems, system components, or system services at organization-defined decision points in the system development life cycle.

    NIST Control Description -
    Identify critical system components and functions by performing a criticality analysis for [Assignment: organization-defined systems, system components, or system services] at [Assignment: organization-defined decision points in the system development life cycle].
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-274
    SA-4(9) - Acquisition Process | Functions, Ports, Protocols, and Services in Use.
    SA System & Services Acq.
    None

    CSP/Vendor Implementation Details -
    The customer is responsible for requiring the developer of the system, system component, or system service to identify the functions, ports, protocols, and services intended for organizational use. Azure services have minimum ports and protocols needed to function, but customers can configure these per service. Azure services can be configured to meet multiple baseline configuration regimes. Information can be found here, but service-specific configuration information can be found on the Azure website for each service as well - https://learn.microsoft.com/en-us/security/benchmark/azure/security-baselines-overview

    NIST Control Description -
    Require the developer of the system, system component, or system service to identify the functions, ports, protocols, and services intended for organizational use.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-282
    SA-10 - Developer Configuration Management.
    SA System & Services Acq.
    None

    CSP/Vendor Implementation Details -
    (a) The customer is responsible for requiring the developer of customer-deployed resources to perform configuration management during the design; development; implementation; operation; and disposal of the resources provided. The customer can find a description of the security controls employed by Azure via the Azure System Security Plan (SSP). For access to the SSP, as well as additional Azure documentation, please contact AzFedDoc@microsoft.com
    (b) The customer is responsible for requiring the developer of customer-deployed resources to document, manage, and control the integrity of changes to customer-defined configuration items. The customer can find a description of the security controls employed by Azure via the Azure System Security Plan (SSP). For access to the SSP, as well as additional Azure documentation, please contact AzFedDoc@microsoft.com
    (c) The customer is responsible for requiring the developer of customer-deployed resources to implement only organization-approved changes to the system, component, or service. The customer can find a description of the security controls employed by Azure via the Azure System Security Plan (SSP). For access to the SSP, as well as additional Azure documentation, please contact AzFedDoc@microsoft.com
    (d) The customer is responsible for requiring the developer of customer-deployed resources to document approved changes to the system, component, or service and the potential security and privacy impacts of such changes. The customer can find a description of the security controls employed by Azure via the Azure System Security Plan (SSP). For access to the SSP, as well as additional Azure documentation, please contact AzFedDoc@microsoft.com
    (e) The customer is responsible for requiring the developer of customer-deployed resources to track security flaws and flaw resolution within the system, component, or service and report findings to organization-defined personnel. The customer can find a description of the security controls employed by Azure via the Azure System Security Plan (SSP). For access to the SSP, as well as additional Azure documentation, please contact AzFedDoc@microsoft.com

    NIST Control Description -
    Require the developer of the system, system component, or system service to:
    a. Perform configuration management during system, component, or service [Selection (one or more): design; development; implementation; operation; disposal];
    b. Document, manage, and control the integrity of changes to [Assignment: organization-defined configuration items under configuration management];
    c. Implement only organization-approved changes to the system, component, or service;
    d. Document approved changes to the system, component, or service and the potential security and privacy impacts of such changes; and
    e. Track security flaws and flaw resolution within the system, component, or service and report findings to [Assignment: organization-defined personnel].
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-283
    SA-11 - Developer Testing and Evaluation.
    SA System & Services Acq.
    None

    CSP/Vendor Implementation Details -
    (a) The customer is responsible for requiring the developer of customer-deployed resources, at all post-design stages of the system development life cycle, to develop and implement a plan for ongoing security and privacy control assessments. The customer can find a description of the security controls employed by Azure via the Azure System Security Plan (SSP). For access to the SSP, as well as additional Azure documentation, please contact AzFedDoc@microsoft.com
    (b) The customer is responsible for requiring the developer of customer-deployed resources, at all post-design stages of the system development life cycle, to perform unit; integration; system; regression testing/evaluation at the organization-defined frequency at the organization-defined depth and coverage levels. The customer can find a description of the security controls employed by Azure via the Azure System Security Plan (SSP). For access to the SSP, as well as additional Azure documentation, please contact AzFedDoc@microsoft.com
    (c) The customer is responsible for requiring the developer of customer-deployed resources, at all post-design stages of the system development life cycle, to produce evidence of the execution of the assessment plan and the results of the testing and evaluation. The customer can find a description of the security controls employed by Azure via the Azure System Security Plan (SSP). For access to the SSP, as well as additional Azure documentation, please contact AzFedDoc@microsoft.com
    (d) The customer is responsible for requiring the developer of customer-deployed resources, at all post-design stages of the system development life cycle, to implement a verifiable flaw remediation process. The customer can find a description of the security controls employed by Azure via the Azure System Security Plan (SSP). For access to the SSP, as well as additional Azure documentation, please contact AzFedDoc@microsoft.com
    (e) The customer is responsible for requiring the developer of customer-deployed resources, at all post-design stages of the system development life cycle, to correct flaws identified during testing and evaluation. The customer can find a description of the security controls employed by Azure via the Azure System Security Plan (SSP). For access to the SSP, as well as additional Azure documentation, please contact AzFedDoc@microsoft.com

    NIST Control Description -
    Require the developer of the system, system component, or system service, at all post-design stages of the system development life cycle, to:
    a. Develop and implement a plan for ongoing security and privacy control assessments;
    b. Perform [Selection (one or more): unit; integration; system; regression] testing/evaluation [Assignment: organization-defined frequency] at [Assignment: organization-defined depth and coverage];
    c. Produce evidence of the execution of the assessment plan and the results of the testing and evaluation;
    d. Implement a verifiable flaw remediation process; and
    e. Correct flaws identified during testing and evaluation.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-287
    SA-15(3) - Development Process, Standards, and Tools | Criticality Analysis.
    SA System & Services Acq.
    None

    CSP/Vendor Implementation Details -
    (a) The customer is responsible for requiring the developer of the system, system component, or system service to perform a criticality analysis at the organization-defined decision points in the system development life cycle. The customer can find a description of the security controls employed by Azure via the Azure System Security Plan (SSP). For access to the SSP, as well as additional Azure documentation, please contact AzFedDoc@microsoft.com
    (b) The customer is responsible for requiring the developer of the system, system component, or system service to perform a criticality analysis at the organization-defined breadth and depth of criticality analysis. The customer can find a description of the security controls employed by Azure via the Azure System Security Plan (SSP). For access to the SSP, as well as additional Azure documentation, please contact AzFedDoc@microsoft.com

    NIST Control Description -
    Require the developer of the system, system component, or system service to perform a criticality analysis:
    (a) At the following decision points in the system development life cycle: [Assignment: organization-defined decision points in the system development life cycle]; and
    (b) At the following level of rigor: [Assignment: organization-defined breadth and depth of criticality analysis].
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-293
    SC-2 - Separation of System and User Functionality.
    SC System & Comm. Protection
    None

    CSP/Vendor Implementation Details -
    The customer is responsible for separating user functionality, including user interface services, from system management functionality. Azure account management information using Azure Active Directory can be found here - https://learn.microsoft.com/en-us/azure/active-directory/fundamentals/whatis

    NIST Control Description -
    Separate user functionality, including user interface services, from system management functionality.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-322
    SC-28 - Protection of Information at Rest.
    SC System & Comm. Protection
    None

    CSP/Vendor Implementation Details -
    The customer is responsible for protecting customer-controlled information at rest. Azure Storage provides the capability for customers to protect their information at rest using Azure SAKs provided by Azure. The SAK is a secret key that is used to manage access to storage. An application that needs to access storage must have possession of this key. It is the customer’s responsibility to protect the SAKs in order to protect their data.

    NIST Control Description -
    Protect the [Selection (one or more): confidentiality; integrity] of the following information at rest: [Assignment: organization-defined information at rest].
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-323
    SC-28(1) - Protection of Information at Rest | Cryptographic Protection.
    SC System & Comm. Protection
    None

    CSP/Vendor Implementation Details -
    The customer is responsible for implementing cryptographic mechanisms to prevent unauthorized disclosure and modification of the organization-defined information at rest on the organization-defined system components or media.

    NIST Control Description -
    Implement cryptographic mechanisms to prevent unauthorized disclosure and modification of the following information at rest on [Assignment: organization-defined system components or media]: [Assignment: organization-defined information].
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-324
    SC-39 - Process Isolation.
    SC System & Comm. Protection
    None

    CSP/Vendor Implementation Details -
    For customers of IaaS and PaaS services, the customer is responsible for maintaining separate execution domains for running processes. Azure Networking protections can be utilized to implement isolation - https://learn.microsoft.com/en-us/azure/networking/fundamentals/networking-overview. In addition, customers can leverage the Azure Architecture Center for additional recommendations - https://learn.microsoft.com/en-us/azure/architecture/

    NIST Control Description -
    Maintain a separate execution domain for each executing system process.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-329
    SI-2(2) - Flaw Remediation | Automated Flaw Remediation Status.
    SI System & Info. Integrity
    L1 or L2 Common Control Catalog Description -
    Vulnerability scans are conducted on connected systems at a minimum frequency of monthly, or as stipulated by policy. Reports generated from these scans are accessible to the ISSO, system owner, and system administrator.

    CSP/Vendor Implementation Details -
    For customers of IaaS and PaaS services, the customer is responsible for determining if system components have applicable security-relevant software and firmware updates installed using organization-defined automated mechanisms at the organization-defined frequency. Customers are able to leverage Defender for Cloud to achieve this - https://learn.microsoft.com/en-us/azure/defender-for-cloud/deploy-vulnerability-assessment-vm

    NIST Control Description -
    Determine if system components have applicable security-relevant software and firmware updates installed using [Assignment: organization-defined automated mechanisms] [Assignment: organization-defined frequency].
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-332
    SI-4 - System Monitoring.
    SI System & Info. Integrity
    L1 or L2 Common Control Catalog Description -
    a. Monitor the system to detect:
    1. The information system incorporates secure mechanisms, such as IDS, IPS, and authentication tools, to monitor and detect attacks, including indicators of potential attacks, in alignment with monitoring objectives.
    2. The information system' design places a strong emphasis on identifying and detecting unauthorized local, network, and remote connections.
    b. Proactive measures, include blocking unauthorized access attempts.
    c. Internal monitoring capabilities:
    1. All collected logs are forward to a log aggregator.
    2. The CSIRT utilizes network TAPs to collect essential logs.
    d. Logs are forwarded to security tools for the purpose of scrutinizing events and anomalies.
    e. Upon guidance from the IARC or another reliable source, CSIRT employs its Incident Response Plan. Collaborating closely with the IARC, they investigate and address the incidents as high-priority.
    f. The IARC provides guidance with regard to information system monitoring activities in accordance with applicable federal laws.
    g. CSIRT receives alerts at least daily, ensuring timely awareness of potential security incidents. The regular alerting mechanism is designed to keep the CSIRT informed, allowing them to promptly assess and respond to emerging threats and incidents.

    CSP/Vendor Implementation Details -
    (a) The customer is responsible for monitoring customer-deployed resources to detect attacks and indicators of potential attacks in accordance with customer-defined monitoring objectives; and unauthorized local, network, and remote connections. Azure services are individually able to generate audit logs that can then be consolidated into a single SIEM, either an Azure service or a customer third party. For guidance on configuring audit logs, please visit - https://learn.microsoft.com/en-us/azure/security/fundamentals/log-audit
    (b) The customer is responsible for identifying unauthorized use of the system through the organization-defined techniques and methods. Azure services are individually able to generate audit logs that can then be consolidated into a single SIEM, either an Azure service or a customer third party. For guidance on configuring audit logs, please visit - https://learn.microsoft.com/en-us/azure/security/fundamentals/log-audit
    (c) The customer is responsible for invoking internal monitoring capabilities or deploy monitoring devices strategically within the system to collect organization-determined essential information; and at ad hoc locations within the system to track specific types of transactions of interest to the organization. Azure services are individually able to generate audit logs that can then be consolidated into a single SIEM, either an Azure service or a customer third party. For guidance on configuring audit logs, please visit - https://learn.microsoft.com/en-us/azure/security/fundamentals/log-audit
    (d) The customer is responsible for analyzing detected events and anomalies. Azure services are individually able to generate audit logs that can then be consolidated into a single SIEM, either an Azure service or a customer third party. For guidance on configuring audit logs, please visit - https://learn.microsoft.com/en-us/azure/security/fundamentals/log-audit
    (e) The customer is responsible for adjusting the level of system monitoring activity when there is a change in risk to organizational operations and assets, individuals, other organizations, or the Nation. Azure services are individually able to generate audit logs that can then be consolidated into a single SIEM, either an Azure service or a customer third party. For guidance on configuring audit logs, please visit - https://learn.microsoft.com/en-us/azure/security/fundamentals/log-audit
    (f) The customer is responsible for obtaining legal opinion with regard to system monitoring activities in accordance with applicable federal laws, Executive Orders, directives, policies, or regulations. Azure services are individually able to generate audit logs that can then be consolidated into a single SIEM, either an Azure service or a customer third party. For guidance on configuring audit logs, please visit - https://learn.microsoft.com/en-us/azure/security/fundamentals/log-audit
    (g) The customer is responsible for providing selected monitoring information to customer-defined personnel/roles as needed and/or at the required frequency. Azure services are individually able to generate audit logs that can then be consolidated into a single SIEM, either an Azure service or a customer third party. For guidance on configuring audit logs, please visit - https://learn.microsoft.com/en-us/azure/security/fundamentals/log-audit

    NIST Control Description -
    a. Monitor the system to detect:
    1. Attacks and indicators of potential attacks in accordance with the following monitoring objectives: [Assignment: organization-defined monitoring objectives]; and
    2. Unauthorized local, network, and remote connections;
    b. Identify unauthorized use of the system through the following techniques and methods: [Assignment: organization-defined techniques and methods];
    c. Invoke internal monitoring capabilities or deploy monitoring devices:
    1. Strategically within the system to collect organization-determined essential information; and
    2. At ad hoc locations within the system to track specific types of transactions of interest to the organization;
    d. Analyze detected events and anomalies;
    e. Adjust the level of system monitoring activity when there is a change in risk to organizational operations and assets, individuals, other organizations, or the Nation;
    f. Obtain legal opinion regarding system monitoring activities; and
    g. Provide [Assignment: organization-defined system monitoring information] to [Assignment: organization-defined personnel or roles] [Selection (one or more): as needed; [Assignment: organization-defined frequency]].
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-333
    SI-4(1) - System Monitoring | System-wide Intrusion Detection System.
    SI System & Info. Integrity
    None

    CSP/Vendor Implementation Details -
    The customer is responsible for connecting and configuring individual intrusion detection tools into a system-wide intrusion detection system Azure services are individually able to generate audit logs that can then be consolidated into a single SIEM, either an Azure service or a customer third party. For guidance on configuring audit logs, please visit - https://learn.microsoft.com/en-us/azure/security/fundamentals/log-audit

    NIST Control Description -
    Connect and configure individual intrusion detection tools into a system-wide intrusion detection system.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-334
    SI-4(2) - System Monitoring | Automated Tools and Mechanisms for Real-time Analysis.
    SI System & Info. Integrity
    L1 or L2 Common Control Catalog Description -
    The organization utilizes security tools, including IDS, to provide near real-time capabilities for analyzing events.

    CSP/Vendor Implementation Details -
    The customer is responsible for monitoring customer-deployed resources using automated mechanisms to support near real-time analysis of events. Azure services are individually able to generate audit logs that can then be consolidated into a single SIEM, either an Azure service or a customer third party. For guidance on configuring audit logs, please visit - https://learn.microsoft.com/en-us/azure/security/fundamentals/log-audit

    NIST Control Description -
    Employ automated tools and mechanisms to support near real-time analysis of events.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-335
    SI-4(4) - System Monitoring | Inbound and Outbound Communications Traffic.
    SI System & Info. Integrity
    L1 or L2 Common Control Catalog Description -
    (a) The organization's security teams develop custom alerts to identify unusual or unauthorized activities in both inbound and outbound communication traffic.
    (b) The organization leverages security tools, including IDS and IPS, to monitor inbound and outbound communications traffic, at least daily.

    CSP/Vendor Implementation Details -
    (a) The customer is responsible for determining criteria for unusual or unauthorized activities or conditions for inbound and outbound communications traffic. Azure services are individually able to generate audit logs that can then be consolidated into a single SIEM, either an Azure service or a customer third party. For guidance on configuring audit logs, please visit - https://learn.microsoft.com/en-us/azure/security/fundamentals/log-audit
    (b) The customer is responsible for monitoring inbound and outbound communications traffic at the organization-defined frequency for the organization-defined unusual or unauthorized activities or conditions. Azure services are individually able to generate audit logs that can then be consolidated into a single SIEM, either an Azure service or a customer third party. For guidance on configuring audit logs, please visit - https://learn.microsoft.com/en-us/azure/security/fundamentals/log-audit

    NIST Control Description -
    (a) Determine criteria for unusual or unauthorized activities or conditions for inbound and outbound communications traffic;
    (b) Monitor inbound and outbound communications traffic [Assignment: organization-defined frequency] for [Assignment: organization-defined unusual or unauthorized activities or conditions].
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-349
    SI-7 - Software, Firmware, and Information Integrity.
    SI System & Info. Integrity
    None

    CSP/Vendor Implementation Details -
    (a) The customer is responsible for employing integrity verification tools to detect unauthorized changes to organization-defined software, firmware, and information.
    (b) The customer is responsible for taking the organization-defined actions when unauthorized changes to the software, firmware, and information are detected.

    NIST Control Description -
    a. Employ integrity verification tools to detect unauthorized changes to the following software, firmware, and information: [Assignment: organization-defined software, firmware, and information]; and
    b. Take the following actions when unauthorized changes to the software, firmware, and information are detected: [Assignment: organization-defined actions].
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-350
    SI-7(1) - Software, Firmware, and Information Integrity | Integrity Checks.
    SI System & Info. Integrity
    None

    CSP/Vendor Implementation Details -
    For customers of IaaS and PaaS services, the customer is responsible for protecting software and information integrity for customer-deployed resources, including performing integrity checks of customer-defined software and information at customer-defined system transitional states (e.g., startup, restart, shutdown, abort), in response to customer-defined security-related events, or at a customer-defined frequency.

    NIST Control Description -
    Perform an integrity check of [Assignment: organization-defined software, firmware, and information] [Selection (one or more): at startup; at [Assignment: organization-defined transitional states or security-relevant events]; [Assignment: organization-defined frequency]].
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-357
    SI-10 - Information Input Validation.
    SI System & Info. Integrity
    None

    CSP/Vendor Implementation Details -
    For customers of IaaS and PaaS services, the customer is responsible for information input validation for customer-deployed resources.

    NIST Control Description -
    Check the validity of the following information inputs: [Assignment: organization-defined information inputs to the system].
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-370
    SR-10 - Inspection of Systems or Components.
    SR Supply Chain Risk Mgmt
    None

    CSP/Vendor Implementation Details -
    For customers of IaaS and PaaS services, the customer is responsible for inspect the organization-defined systems or system components at random; at an organization-defined frequency; or upon organization-defined indications of need for inspection to detect tampering. Customers can implement Microsoft's supply chain management recommendations to assist with this requirement - https://www.microsoft.com/en-us/microsoft-cloud/solutions/microsoft-supply-chain-platform#products

    NIST Control Description -
    Inspect the following systems or system components [Selection (one or more): at random; at [Assignment: organization-defined frequency], upon [Assignment: organization-defined indications of need for inspection]] to detect tampering: [Assignment: organization-defined systems or system components].
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-97
    AU-11 - Audit Record Retention.
    AU Audit & Account.
    L1 or L2 Common Control Catalog Description -
    The information system audit records are retained for two (2) years. These logs will be usable for incident response investigations.

    CSP/Vendor Implementation Details -
    The customer is responsible for retaining audit records for customer-deployed resources for the organization-defined time period consistent with records retention policy to provide support for after-the-fact investigations of incidents and to meet regulatory and organizational information retention requirements. Standard retention is 90 days, but Azure offers longer-term storage options including Azure Monitor and Azure Storage. Azure services are individually able to generate audit logs that can then be consolidated into a single SIEM, either an Azure service or a customer third party. For guidance on configuring audit logs, please visit - https://learn.microsoft.com/en-us/azure/security/fundamentals/log-audit

    NIST Control Description -
    Retain audit records for [Assignment: organization-defined time period consistent with records retention policy] to provide support for after-the-fact investigations of incidents and to meet regulatory and organizational information retention requirements.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-98
    AU-12 - Audit Record Generation.
    AU Audit & Account.
    L1 or L2 Common Control Catalog Description -
    a. The log management tool aggregates audit records from information systems, providing the capability for centrally storing auditable events defined in AU-2.
    b. The ISSO, in collaboration with relevant teams, customize reports to adhere to policy requirements.
    c. Systems are configured to generate audit records containing sufficient information as defined in AU-2 and AU-3.

    CSP/Vendor Implementation Details -
    (a) The customer is responsible for providing an audit record generation capability for the event types the system is capable of auditing as defined in AU-2a on the organization-defined system components. Azure audit logs can be utilized to meet this requirement. Azure services are individually able to generate audit logs that can then be consolidated into a single SIEM, either an Azure service or a customer third party. For guidance on configuring audit logs, please visit - https://learn.microsoft.com/en-us/azure/security/fundamentals/log-audit
    (b) The customer is responsible for allowing organization-defined personnel or roles to select the event types that are to be logged by specific customer-deployed components of the system. Azure services are individually able to generate audit logs that can then be consolidated into a single SIEM, either an Azure service or a customer third party. For guidance on configuring audit logs, please visit - https://learn.microsoft.com/en-us/azure/security/fundamentals/log-audit
    (c) The customer is responsible for generating audit records for the event types defined in AU-2c that include the audit record content defined in AU-3. Azure audit logs can be utilized to meet this requirement. Azure services are individually able to generate audit logs that can then be consolidated into a single SIEM, either an Azure service or a customer third party. For guidance on configuring audit logs, please visit - https://learn.microsoft.com/en-us/azure/security/fundamentals/log-audit

    NIST Control Description -
    a. Provide audit record generation capability for the event types the system is capable of auditing as defined in AU-2a on [Assignment: organization-defined system components];
    b. Allow [Assignment: organization-defined personnel or roles] to select the event types that are to be logged by specific components of the system; and
    c. Generate audit records for the event types defined in AU-2c that include the audit record content defined in AU-3.
    Issue Type: Task
    Priority: Lowest
     
    CCACCR-296
    SC-5 - Denial-of-service Protection.
    SC System & Comm. Protection
    L1 or L2 Common Control Catalog Description -
    a. The organization implemented a defense strategy against Denial-of-Service (DoS) attacks, particularly those involving network flooding. Employ a multi-layered security approach utilizing Intrusion Prevention System (IPS) tools, boundary firewalls, router filters, and regular system patching.
    b. The information system utilizes specific technologies to support the defense strategy against common Denial-of-Service (DoS) attacks.

    CSP/Vendor Implementation Details -
    (a) The customer is responsible for protecting against or limiting the effects of the organization-defined types of denial-of-service events. Customers can utilize Azure Network protections or deploy Azure DDoS Protection - https://learn.microsoft.com/en-us/azure/ddos-protection/ddos-protection-overview
    (b) The customer is responsible for employing the organization-defined controls by type of denial-of-service event to achieve the denial-of-service objective. Customers can utilize Azure Network protections or deploy Azure DDoS Protection - https://learn.microsoft.com/en-us/azure/ddos-protection/ddos-protection-overview

    NIST Control Description -
    a. [Selection: Protect against; Limit] the effects of the following types of denial-of-service events: [Assignment: organization-defined types of denial-of-service events]; and
    b. Employ the following controls to achieve the denial-of-service objective: [Assignment: organization-defined controls by type of denial-of-service event].
    Issue Type: Task
    Priority: Lowest
     
    (SA/ENG) Configure Environment: Unassigned swimlane
    (SA/ENG) Provide Implementation Details & Evidence: Unassigned swimlane
    (ISSO) Verify Implementation Details & Evidence: Unassigned swimlane
    (SCA) Validate Evidence: Unassigned swimlane
    (ISSM) Validate Evidence: Unassigned swimlane
    Quality Assurance: Unassigned swimlane
    Done: Unassigned swimlane
