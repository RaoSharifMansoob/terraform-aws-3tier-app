# Terraform AWS 3-Tier Application Infrastructure

A hands-on Infrastructure as Code (IaC) project that provisions a three-tier application infrastructure on Amazon Web Services (AWS) using Terraform.

The project focuses on a simple, secure, cost-conscious, and modular design while demonstrating AWS networking, load balancing, EC2 Auto Scaling, RDS PostgreSQL, IAM, security groups, remote Terraform state, and code-quality checks.

> **Project status:** The development environment has been deployed and tested. The Application Load Balancer returns HTTP 200, and the application targets are healthy. The demonstration web server does not yet connect to PostgreSQL. Production environment configuration is not yet implemented.

## Table of Contents

- [1. Project Overview](#1-project-overview)
- [2. Architecture](#2-architecture)
- [3. AWS Resources](#3-aws-resources)
- [4. Security Design](#4-security-design)
- [5. Repository Structure](#5-repository-structure)
- [6. Prerequisites](#6-prerequisites)
- [7. AWS Authentication](#7-aws-authentication)
- [8. Remote Terraform State](#8-remote-terraform-state)
- [9. Deployment Guide](#9-deployment-guide)
- [10. Verification and Testing](#10-verification-and-testing)
- [11. Code Quality and Pre-Commit](#11-code-quality-and-pre-commit)
- [12. Troubleshooting](#12-troubleshooting)
- [13. Cost Considerations](#13-cost-considerations)
- [14. Cleanup and Resource Destruction](#14-cleanup-and-resource-destruction)
- [15. Limitations and Future Improvements](#15-limitations-and-future-improvements)

---

## 1. Project Overview

The project separates the infrastructure into three logical tiers:

1. **Web tier:** An internet-facing Application Load Balancer (ALB) receives HTTP requests.
2. **Application tier:** An EC2 Auto Scaling Group runs two EC2 instances in private application subnets.
3. **Database tier:** Amazon RDS for PostgreSQL runs in private database subnets and accepts PostgreSQL traffic from the application security group.

The network spans two Availability Zones. The application instances are distributed across private subnets, while the ALB uses public subnets.

### Project objectives

- Provision AWS infrastructure using Terraform.
- Organize infrastructure into reusable modules.
- Keep environment-specific configuration separate from shared infrastructure code.
- Apply least-privilege IAM and security-group rules.
- Store application Terraform state in an encrypted, versioned S3 bucket.
- Use S3 lockfiles for Terraform state locking.
- Run formatting and secret-detection checks before commits.
- Avoid unnecessary infrastructure costs, including NAT Gateway charges.

## 2. Architecture

### High-level architecture

```text
                        Internet
                           |
                           v
                 +--------------------+
                 | Application Load   |
                 | Balancer (HTTP 80) |
                 +---------+----------+
                           |
                +----------+----------+
                |                     |
                v                     v
          +-----------+         +-----------+
          | EC2 App 1 |         | EC2 App 2 |
          | Private   |         | Private   |
          | Subnet AZ1|         | Subnet AZ2|
          +-----+-----+         +-----+-----+
                |                     |
                +----------+----------+
                           |
                           v
                 +--------------------+
                 |   RDS PostgreSQL   |
                 |    Private DB      |
                 +--------------------+
```

The diagram represents the intended network and traffic flow. The current application is a demonstration HTTP server; it does not yet perform database queries.

### Development network layout

The development VPC uses the CIDR `10.0.0.0/16`.

| Tier | Subnet | CIDR |
|---|---|---|
| Public | `public_a` | `10.0.1.0/24` |
| Public | `public_b` | `10.0.2.0/24` |
| Application | `app_a` | `10.0.11.0/24` |
| Application | `app_b` | `10.0.12.0/24` |
| Database | `db_a` | `10.0.21.0/24` |
| Database | `db_b` | `10.0.22.0/24` |

The subnet labels are logical identifiers. AWS selects the actual Availability Zones through Terraform data sources.

## 3. AWS Resources

| Resource | Purpose |
|---|---|
| Amazon VPC | Provides isolated network addressing. |
| Six subnets | Separates public, application, and database tiers across two Availability Zones. |
| Internet Gateway and route tables | Provide internet routing for public subnets. |
| Security groups | Restrict traffic between the ALB, application, and database tiers. |
| Application Load Balancer | Receives public HTTP requests. |
| Target group and listener | Forward requests to EC2 targets and check application health. |
| EC2 launch template | Defines the AMI, instance type, IAM profile, storage, metadata options, and user data. |
| Auto Scaling Group | Maintains two application instances. |
| IAM role and instance profile | Provide an EC2 identity without static AWS credentials. |
| Amazon RDS for PostgreSQL | Provides a managed relational database. |
| RDS DB subnet group | Places RDS in the private database subnets. |
| Amazon S3 | Stores remote Terraform state separately from the application resources. |

### Main development configuration

| Setting | Value |
|---|---|
| AWS region | `us-east-1` |
| EC2 instance type | `t3.micro` |
| ASG desired/minimum/maximum | `2 / 2 / 2` |
| Application port | TCP `80` |
| Database engine | PostgreSQL 17 |
| Database instance class | `db.t4g.micro` |
| Database storage | 20 GB encrypted gp3 |
| Database public accessibility | Disabled |
| RDS Multi-AZ deployment | Disabled |
| NAT Gateway | Not provisioned |
| Application protocol | HTTP |

The AMI is selected using a Terraform data source, so the matching AMI may change as newer images become available.

## 4. Security Design

### Network isolation

- The ALB is internet-facing and deployed in public subnets.
- EC2 instances run in private application subnets.
- RDS runs in private database subnets and is not publicly accessible.
- The database security group accepts TCP `5432` only from the application security group.

### Security-group traffic

| Security group | Direction | Allowed traffic |
|---|---|---|
| ALB | Inbound | TCP `80` from the internet |
| ALB | Outbound | TCP `80` to the application security group |
| Application | Inbound | TCP `80` from the ALB security group |
| Application | Outbound | TCP `5432` to the database security group |
| Database | Inbound | TCP `5432` from the application security group |
| Database | Outbound | No explicitly configured outbound rules |

The configuration uses explicit security-group rules rather than relying on the default allow-all egress rule.

### IAM and instance metadata

- The EC2 role has no additional AWS service permissions because the demo web server does not need to call AWS APIs.
- The launch template requires IMDSv2.
- The Terraform execution role should receive only the permissions required to manage this project.
- IAM permissions should not be expanded to administrator access simply to bypass individual access-denied errors.

### Storage and state protection

- EC2 root volumes use encrypted gp3 storage.
- RDS storage encryption is enabled.
- The S3 state bucket has versioning, encryption, and S3 Block Public Access enabled.
- The S3 backend uses `encrypt = true` and `use_lockfile = true`.
- `.gitignore` excludes local Terraform working directories, state files, and real variable files.
- Gitleaks runs as part of the pre-commit checks.

**Important:** Terraform state may contain sensitive values, including database credentials. Marking a variable as sensitive does not encrypt or remove its value from state. Restrict access to the state bucket and its object versions.

### Current security limitations

This is a learning project, not a production-ready application. It currently uses HTTP rather than HTTPS and does not include a domain, TLS certificate, production application stack, or complete monitoring and alerting.

## 5. Repository Structure

```text
terraform-aws-3tier-app/
├── bootstrap/
│   ├── main.tf
│   ├── provider.tf
│   ├── variables.tf
│   ├── versions.tf
│   └── terraform.tfvars.example
├── environments/
│   └── dev/
│       ├── main.tf
│       ├── outputs.tf
│       ├── provider.tf
│       ├── variables.tf
│       ├── versions.tf
│       ├── terraform.tfvars.example
│       └── .terraform.lock.hcl
├── modules/
│   ├── networking/
│   ├── security/
│   ├── load_balancer/
│   ├── compute/
│   └── database/
├── .gitignore
├── .pre-commit-config.yaml
└── README.md
```

The directory tree lists the important tracked configuration files, not generated files or local-only files.

### Directory responsibilities

| Directory or file | Responsibility |
|---|---|
| `bootstrap/` | Creates the S3 bucket used for remote Terraform state. |
| `environments/dev/` | Configures and deploys the development environment. |
| `modules/networking/` | Defines the VPC, subnets, Internet Gateway, and route tables. |
| `modules/security/` | Defines tier-specific security groups and their rules. |
| `modules/load_balancer/` | Defines the ALB, listener, target group, and health checks. |
| `modules/compute/` | Defines the EC2 launch template, IAM role/profile, and Auto Scaling Group. |
| `modules/database/` | Defines RDS PostgreSQL and its subnet group. |
| `.gitignore` | Excludes local files, state, and sensitive configuration. |
| `.pre-commit-config.yaml` | Defines local formatting and security checks. |

The `environments/prod/` directory is not configured for deployment yet. Production resources, variables, and state should be added deliberately in a future iteration.

## 6. Prerequisites

Install the following tools:

- [Terraform](https://developer.hashicorp.com/terraform/install)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [Git](https://git-scm.com/downloads)
- Python and the Python Launcher on Windows
- The Python `pre-commit` package

Verify the installation in PowerShell:

```powershell
terraform version
aws --version
git --version
py --version
py -m pre_commit --version
```

Use a Terraform version compatible with the project's version constraints and preserve the committed provider lockfile.

You also need an AWS account, an IAM identity with appropriately scoped permissions, and a remote-state S3 bucket before initializing the development environment.

## 7. AWS Authentication

The original development workflow uses these AWS CLI profiles:

- `terraform-dev` — authenticates the IAM user.
- `terraform-project1` — assumes the dedicated `TerraformProject1Role`.

These profile names are specific to the original local setup. Configure equivalent profiles for your own AWS account.

### Authenticate

```powershell
aws login --profile terraform-dev
```

Verify the identity used for Terraform:

```powershell
aws sts get-caller-identity --profile terraform-project1
```

Confirm the AWS account and role before making infrastructure changes.

The Terraform provider and S3 backend are configured to use the `terraform-project1` profile. If your local AWS configuration differs, update the profile configuration consistently before proceeding.

Do not hardcode AWS access keys in Terraform files. Never commit credentials, secret-bearing terminal exports, real `.tfvars` files, or Terraform state.

## 8. Remote Terraform State

The development environment stores its state remotely in Amazon S3.

| Setting | Value |
|---|---|
| Bucket | `terraform-aws-3tier-app-state-949049116271` |
| Region | `us-east-1` |
| Development state key | `terraform-aws-3tier-app/dev/terraform.tfstate` |
| Encryption | Enabled |
| Bucket versioning | Enabled |
| S3 Block Public Access | Enabled |
| State locking | S3 lockfile |

The bucket name is specific to the original AWS account. If deploying to another account, use a globally unique bucket name owned by that account and update the backend configuration accordingly.

### Why remote state?

Remote state centralizes Terraform's resource mapping and metadata. Versioning helps recover previous state versions, and S3 lockfiles help prevent concurrent Terraform operations from modifying the same state simultaneously.

These controls do not replace restrictive IAM permissions and appropriate bucket policies.

### Bootstrap configuration

The `bootstrap/` directory creates the S3 bucket and its foundational security settings.

Bootstrap is separate from the application environment. It may use its own local state file, so keep its state and configuration separate from the development environment's remote state.

If the state bucket already exists, do not attempt to recreate it. Before using bootstrap for a new account, review its variables, initialize it from the `bootstrap/` directory, inspect the plan, and apply only after confirming the bucket configuration.

**Do not destroy or delete the state bucket while an active Terraform backend depends on it.**

## 9. Deployment Guide

The following instructions deploy the configured development environment.

### Step 1: Clone the repository

```powershell
git clone https://github.com/RaoSharifMansoob/terraform-aws-3tier-app.git
Set-Location terraform-aws-3tier-app
```

### Step 2: Configure development variables

```powershell
Copy-Item environments\dev\terraform.tfvars.example environments\dev\terraform.tfvars
```

Edit `environments\dev\terraform.tfvars` and supply the values required by the configuration. Use a strong database password and never commit the real variable file.

The example file should contain safe placeholder values only.

### Step 3: Authenticate to AWS

```powershell
aws login --profile terraform-dev
aws sts get-caller-identity --profile terraform-project1
```

Verify that the expected account and role are active.

### Step 4: Initialize the development environment

```powershell
Set-Location environments\dev
terraform init
```

Run Terraform commands from `environments\dev`, not from the repository root. This ensures Terraform uses the correct provider configuration, backend key, variables, and module references.

### Step 5: Validate the configuration

```powershell
terraform fmt -check -recursive
terraform validate
```

If you change files, format them before validating again.

### Step 6: Review the execution plan

```powershell
terraform plan
```

Review all proposed changes. Confirm the AWS account, region, instance sizes, database configuration, and estimated cost before applying.

### Step 7: Apply the configuration

```powershell
terraform apply
```

Review the final plan and confirm the operation when prompted. Avoid automatic approval until you understand the proposed changes.

### Step 8: Retrieve outputs

```powershell
terraform output
```

The configured outputs include the ALB URL, VPC ID, Auto Scaling Group name, and RDS connection information.

The RDS endpoint is an address, not a database password. Its availability does not mean that RDS is publicly accessible.

## 10. Verification and Testing

### Check Terraform configuration and drift

From `environments/dev/`:

```powershell
terraform validate
terraform plan
```

After a successful deployment, a no-change plan is expected if the actual AWS infrastructure matches the configuration and no out-of-band changes have occurred.

### Test the ALB

Retrieve the application URL:

```powershell
terraform output -raw alb_url
```

Send a request:

```powershell
$url = terraform output -raw alb_url
Invoke-WebRequest -Uri $url -UseBasicParsing
```

The demonstration application should return HTTP `200 OK` with:

```text
Hello from Terraform!
```

### Check target health

If targets are unhealthy, inspect the target group health status, instance lifecycle, application logs, user-data execution, and security-group rules.

The ALB must be able to reach the application instances on TCP port `80`. The application instances must listen on that port and allow inbound traffic from the ALB security group.

### Database verification

RDS is provisioned in private subnets, and the database security group permits PostgreSQL traffic from the application security group. However, the current demonstration server does not connect to or query the database. Database connectivity and authentication must be tested separately when application-to-database integration is implemented.

## 11. Code Quality and Pre-Commit

The repository uses pre-commit hooks for basic quality and security checks, including:

- YAML validation
- End-of-file newline checks
- Trailing-whitespace checks
- Terraform formatting
- Gitleaks secret detection

Install the hooks from the repository root:

```powershell
py -m pre_commit install
```

Run all checks before committing:

```powershell
py -m pre_commit run --all-files
```

Run this command from the repository root so the hooks can inspect the full repository.

Terraform commands do not automatically run pre-commit hooks. The hooks run when Git invokes the configured pre-commit hook, or when you execute them manually.

If a hook modifies a file, review and stage the changes before committing.

## 12. Troubleshooting

### Terraform cannot authenticate to AWS

Refresh the login session and verify the assumed identity:

```powershell
aws login --profile terraform-dev
aws sts get-caller-identity --profile terraform-project1
```

Confirm that the Terraform provider and backend use the expected profile.

### Access denied during apply

Review the denied action and resource ARN. Grant only the narrowly scoped permissions required for the operation. Avoid broad administrator permissions as a workaround.

### ALB returns 502 or 504, or targets are unhealthy

Check:

- Target group health status and reason.
- EC2 instance lifecycle and Auto Scaling health.
- ALB and application security-group ingress and egress rules.
- Whether the application is listening on port `80`.
- Whether user data completed successfully.
- Whether the correct target group and security groups are attached.

Private application subnets do not have NAT-based internet access. Startup scripts that download operating-system packages may fail unless the necessary network path or package source is available.

### Terraform reports provider or memory errors

Close unnecessary applications, retry after reducing memory pressure, and preserve the committed provider lockfile unless there is a deliberate reason to change provider versions.

### Pre-commit modifies files

```powershell
py -m pre_commit run --all-files
git status
git add .
```

Review the changes before committing.

### Terraform proposes unexpected changes

Do not apply immediately. Check the active directory, backend, AWS account, region, variables, state, and resource configuration. Review the plan before taking action.

## 13. Cost Considerations

This is a learning environment, not a zero-cost deployment.

Potential charges include:

- Application Load Balancer hourly and capacity-related usage.
- Two running EC2 instances and their EBS volumes.
- RDS instance-hours and allocated database storage.
- S3 storage, requests, and stored object versions.
- Data transfer and other AWS services enabled later.

The configuration avoids a NAT Gateway and uses small instance sizes to reduce costs. RDS is not Multi-AZ, and the Auto Scaling Group is configured to maintain two instances.

Actual costs depend on region, usage, current pricing, and applicable AWS free-tier eligibility. Review the [AWS Pricing Calculator](https://calculator.aws/) before deployment and monitor AWS billing.

**Important:** Resources continue to incur charges while they exist, even when the application is not being tested.

## 14. Cleanup and Resource Destruction

Destroy the development infrastructure only when you no longer need it.

### Step 1: Confirm the environment and AWS identity

```powershell
aws sts get-caller-identity --profile terraform-project1
Set-Location environments\dev
```

Confirm that you are targeting the correct account and development state.

### Step 2: Review the destruction plan

```powershell
terraform plan -destroy
```

Inspect the resources Terraform proposes to delete. Ensure that the plan targets only the infrastructure you intend to remove.

### Step 3: Destroy the development infrastructure

```powershell
terraform destroy
```

Review the plan and confirm the operation when prompted.

Destroying the application infrastructure is potentially irreversible. Back up any database data you need before deleting RDS, and verify the configured snapshot and deletion behavior before confirming.

### Step 4: Preserve the remote-state backend

The S3 state bucket is managed separately through the bootstrap configuration. Do not destroy it as part of ordinary application cleanup.

Keep the bucket while any Terraform state depends on it. If you eventually remove the backend, first plan a deliberate state archival or migration procedure.

## 15. Limitations and Future Improvements

The current scope prioritizes a straightforward, understandable infrastructure foundation.

Potential future improvements include:

- HTTPS using AWS Certificate Manager and an appropriate domain.
- A real application server and deployment pipeline.
- Application-to-RDS connectivity and integration tests.
- Additional monitoring, logging, alarms, and dashboards.
- Automated Terraform and security checks in CI/CD.
- Managed application secrets.
- A deliberate database backup and recovery strategy.
- NAT Gateway or selected VPC endpoints if future requirements need outbound connectivity.
- A separately configured production environment with its own state and variables.

These are future improvements, not features the current configuration claims to have implemented.

---

Contributions and suggestions are welcome. Make focused changes, run the repository's pre-commit checks, validate Terraform from the relevant environment directory, and review the plan before applying infrastructure changes.

Never commit AWS credentials, database passwords, real `.tfvars` files, Terraform state, or other sensitive information.
