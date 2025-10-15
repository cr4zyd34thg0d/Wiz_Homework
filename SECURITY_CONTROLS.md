# Security Controls & NIST SP 800-53 Rev 5 Mapping

## Overview
This document maps the security vulnerabilities and controls in this environment to NIST SP 800-53 Rev 5 controls, demonstrating how security tools like Wiz help organizations maintain compliance with federal security standards.

## 🚨 Security Vulnerabilities & NIST SP 800-53 Rev 5 Controls

### 1. Public S3 Bucket (Data Exposure)
**Vulnerability**: Database backups publicly accessible
**Risk**: Data breach, unauthorized data access, compliance violations

**NIST SP 800-53 Rev 5 Controls:**
- **AC-3 (Access Enforcement)**: Control unauthorized access to information resources
- **AC-4 (Information Flow Enforcement)**: Control information flows within the system
- **SC-28 (Protection of Information at Rest)**: Protect confidentiality and integrity of stored information
- **SI-4 (System Monitoring)**: Monitor system events and unauthorized access attempts
- **MP-2 (Media Access)**: Restrict access to digital and non-digital media

**Control Implementation Gap**: Missing access controls on S3 bucket allowing public read access
**Detection Method**: AWS Config rule `S3_BUCKET_PUBLIC_READ_PROHIBITED`

### 2. SSH Access from Anywhere (Network Exposure)
**Vulnerability**: MongoDB VM accessible via SSH from 0.0.0.0/0
**Risk**: Brute force attacks, unauthorized system access, lateral movement

**NIST SP 800-53 Rev 5 Controls:**
- **AC-4 (Information Flow Enforcement)**: Control network traffic flows and connections
- **SC-7 (Boundary Protection)**: Monitor and control communications at external system boundaries
- **AC-17 (Remote Access)**: Establish usage restrictions and implementation guidance for remote access
- **SI-4 (System Monitoring)**: Monitor network connections and unusual activity
- **CM-7 (Least Functionality)**: Configure systems to provide only essential capabilities

**Control Implementation Gap**: Security group allows SSH (port 22) from 0.0.0.0/0 instead of specific IP ranges
**Detection Method**: Security group analysis, network vulnerability scanning

### 3. Excessive IAM Permissions (Privilege Escalation)
**Vulnerability**: MongoDB VM has ec2:*, s3:*, iam:PassRole permissions
**Risk**: Privilege escalation, unauthorized resource creation, lateral movement

**NIST SP 800-53 Rev 5 Controls:**
- **AC-2 (Account Management)**: Manage system accounts including creation, enabling, modification, and removal
- **AC-6 (Least Privilege)**: Employ principle of least privilege for specific security functions and privileged accounts
- **AC-6(1) (Least Privilege | Authorize Access to Security Functions)**: Authorize access only to explicitly authorized personnel
- **AC-6(2) (Least Privilege | Non-Privileged Access for Nonsecurity Functions)**: Require non-privileged accounts for non-security functions
- **AU-2 (Event Logging)**: Identify types of events to be logged by the system

**Control Implementation Gap**: IAM role grants wildcard permissions (ec2:*, s3:*) violating least privilege principle
**Detection Method**: IAM policy analysis, privilege escalation path detection

### 4. Outdated Software Stack (Known CVEs)
**Vulnerability**: Ubuntu 20.04, MongoDB 4.4, Node.js 16.14.0 (4+ years old with known CVEs)
**Risk**: Remote code execution, denial of service, exploitation of known vulnerabilities

**NIST SP 800-53 Rev 5 Controls:**
- **SI-2 (Flaw Remediation)**: Identify, report, and correct system flaws in a timely manner
- **SI-2(2) (Flaw Remediation | Automated Flaw Remediation Status)**: Employ automated mechanisms to determine state of system components
- **RA-5 (Vulnerability Monitoring and Scanning)**: Monitor and scan for vulnerabilities and remediate flaws
- **CM-8 (System Component Inventory)**: Develop and document an inventory of system components
- **SA-22 (Unsupported System Components)**: Replace unsupported system components in a timely manner

**Control Implementation Gap**: Systems running end-of-life or outdated software versions with known CVEs
**Detection Method**: Vulnerability scanning (Trivy), software inventory management

### 5. Container Vulnerabilities (Supply Chain Risk)
**Vulnerability**: Outdated base images (Node.js 16.14.0, Alpine 3.15) with known security flaws
**Risk**: Container escape, malware injection, supply chain compromise

**NIST SP 800-53 Rev 5 Controls:**
- **SA-15 (Development Process, Standards, and Tools)**: Require developer to follow documented development process
- **SI-3 (Malicious Code Protection)**: Implement malicious code protection mechanisms
- **SI-7 (Software, Firmware, and Information Integrity)**: Employ integrity verification tools to detect unauthorized changes
- **SR-3 (Supply Chain Controls and Processes)**: Ensure supply chain elements, processes, and actors are authentic and complete
- **SR-4 (Provenance)**: Document, monitor, and maintain valid provenance of system components

**Control Implementation Gap**: Container images not scanned for vulnerabilities before deployment
**Detection Method**: Container image scanning in CI/CD pipeline (Trivy)

### 6. Kubernetes Over-Privileges (Cluster Takeover)
**Vulnerability**: Service account with cluster-admin role binding
**Risk**: Full cluster compromise, unauthorized workload access, privilege escalation

**NIST SP 800-53 Rev 5 Controls:**
- **AC-6 (Least Privilege)**: Employ principle of least privilege for specific security functions
- **AC-6(1) (Least Privilege | Authorize Access to Security Functions)**: Authorize access only to explicitly authorized security functions
- **AC-2 (Account Management)**: Manage system accounts and associated access authorizations
- **AU-2 (Event Logging)**: Identify types of events to be logged by the system
- **AC-3 (Access Enforcement)**: Enforce approved authorizations for logical access

**Control Implementation Gap**: Service account granted cluster-admin instead of minimal required permissions
**Detection Method**: RBAC analysis, Kubernetes security posture assessment

## 🛡️ Implemented Security Controls (NIST SP 800-53 Rev 5)

### Detective Controls

#### AWS Config (Configuration Management & Monitoring)
**NIST SP 800-53 Rev 5 Controls Addressed:**
- **CM-6 (Configuration Settings)**: Establish and document configuration settings
- **CM-3 (Configuration Change Control)**: Control changes to system configurations
- **SI-4 (System Monitoring)**: Monitor system events and activities
- **CA-7 (Continuous Monitoring)**: Develop continuous monitoring strategy

**Implementation**: 
- S3_BUCKET_PUBLIC_READ_PROHIBITED rule
- S3_BUCKET_SSL_REQUESTS_ONLY rule  
- CLOUD_TRAIL_ENABLED rule

#### CloudTrail (Audit and Accountability)
**NIST SP 800-53 Rev 5 Controls Addressed:**
- **AU-2 (Event Logging)**: Identify types of events to be logged
- **AU-3 (Content of Audit Records)**: Ensure audit records contain required information
- **AU-12 (Audit Record Generation)**: Provide audit record generation capability
- **AU-6 (Audit Record Review, Analysis, and Reporting)**: Review and analyze audit records

**Implementation**: Multi-region API logging, centralized log storage

#### Container Security Scanning (Supply Chain Security)
**NIST SP 800-53 Rev 5 Controls Addressed:**
- **SI-2 (Flaw Remediation)**: Identify and correct system flaws
- **RA-5 (Vulnerability Monitoring and Scanning)**: Monitor and scan for vulnerabilities
- **SA-15 (Development Process, Standards, and Tools)**: Follow documented development processes
- **SR-3 (Supply Chain Controls and Processes)**: Ensure supply chain authenticity

**Implementation**: Trivy scanning in GitHub Actions CI/CD pipeline

### Preventative Controls

#### Network Segmentation (Boundary Protection)
**NIST SP 800-53 Rev 5 Controls Addressed:**
- **SC-7 (Boundary Protection)**: Monitor and control communications at system boundaries
- **AC-4 (Information Flow Enforcement)**: Control information flows within and between systems
- **SC-7(3) (Boundary Protection | Access Points)**: Limit number of external network connections

**Implementation**: EKS in private subnets, NAT Gateway, security groups

#### IAM Policies (Access Control)
**NIST SP 800-53 Rev 5 Controls Addressed:**
- **AC-3 (Access Enforcement)**: Enforce approved authorizations for logical access
- **AC-6 (Least Privilege)**: Employ principle of least privilege
- **AC-2 (Account Management)**: Manage system accounts and access authorizations

**Implementation**: IAM deny policies, role-based access control

#### Infrastructure as Code (Configuration Management)
**NIST SP 800-53 Rev 5 Controls Addressed:**
- **CM-2 (Baseline Configuration)**: Develop, document, and maintain baseline configurations
- **CM-3 (Configuration Change Control)**: Control changes to system configurations  
- **CM-9 (Configuration Management Plan)**: Develop and implement configuration management plan
- **SA-10 (Developer Configuration Management)**: Require developer to perform configuration management

**Implementation**: Terraform for infrastructure, version control, peer review

## 📊 NIST SP 800-53 Rev 5 Control Family Coverage

### Access Control (AC)
- **AC-2**: Account Management ✅ (IAM roles and policies)
- **AC-3**: Access Enforcement ✅ (IAM policies, RBAC)
- **AC-4**: Information Flow Enforcement ⚠️ (Network controls present, but gaps exist)
- **AC-6**: Least Privilege ❌ (Over-privileged accounts identified)
- **AC-17**: Remote Access ❌ (SSH open to internet)

### Audit and Accountability (AU)
- **AU-2**: Event Logging ✅ (CloudTrail implementation)
- **AU-3**: Content of Audit Records ✅ (Comprehensive logging)
- **AU-6**: Audit Record Review ⚠️ (Logging present, analysis needed)
- **AU-12**: Audit Record Generation ✅ (Automated logging)

### Configuration Management (CM)
- **CM-2**: Baseline Configuration ✅ (Infrastructure as Code)
- **CM-3**: Configuration Change Control ✅ (Version control, peer review)
- **CM-6**: Configuration Settings ⚠️ (Some misconfigurations present)
- **CM-7**: Least Functionality ❌ (Excessive permissions granted)
- **CM-8**: System Component Inventory ⚠️ (Partial inventory through tagging)

### Risk Assessment (RA)
- **RA-5**: Vulnerability Monitoring and Scanning ✅ (Container scanning, AWS Config)

### System and Communications Protection (SC)
- **SC-7**: Boundary Protection ⚠️ (Network segmentation present, but SSH exposure)
- **SC-28**: Protection of Information at Rest ❌ (Public S3 bucket)

### System and Information Integrity (SI)
- **SI-2**: Flaw Remediation ❌ (Outdated software components)
- **SI-3**: Malicious Code Protection ⚠️ (Container scanning in pipeline)
- **SI-4**: System Monitoring ✅ (CloudTrail, AWS Config)
- **SI-7**: Software, Firmware, and Information Integrity ⚠️ (Some integrity checks)

## 🔍 How Wiz Would Help

### Comprehensive Visibility
- **Asset Discovery**: Automatic inventory of all cloud resources
- **Configuration Assessment**: Real-time compliance monitoring
- **Vulnerability Management**: Continuous scanning across infrastructure and applications

### Risk Prioritization
- **Contextual Risk Scoring**: Business impact-based prioritization
- **Attack Path Analysis**: Understanding how vulnerabilities can be chained
- **Compliance Mapping**: Automatic mapping to regulatory requirements

### Remediation Guidance
- **Actionable Recommendations**: Specific steps to fix issues
- **Policy as Code**: Infrastructure security policies
- **Integration**: Native integration with CI/CD and cloud platforms

## 📊 Metrics & KPIs

### Security Metrics
- **Mean Time to Detection (MTTD)**: How quickly new vulnerabilities are identified
- **Mean Time to Remediation (MTTR)**: How quickly issues are resolved
- **Vulnerability Density**: Number of vulnerabilities per application/service
- **Compliance Score**: Percentage of controls implemented correctly

### Business Metrics
- **Risk Reduction**: Quantified reduction in security risk
- **Cost Avoidance**: Prevented security incidents and their costs
- **Operational Efficiency**: Reduced manual security tasks
- **Audit Readiness**: Time to prepare for compliance audits

This environment demonstrates how modern security tools like Wiz provide comprehensive visibility, risk assessment, and compliance management across cloud-native applications and infrastructure.