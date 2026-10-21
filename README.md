# Terraform AWS 3-Tier Application Infrastructure

Infrastructure as Code (IaC) project that provisions a three-tier AWS architecture using Terraform. The project demonstrates practical AWS networking, load balancing, compute, database provisioning, IAM, security groups, remote state management, and Terraform code-quality checks.

The goal is to build a simple, secure, reproducible, and cost-conscious foundation while keeping the configuration understandable for learning and further development.

> **Project status:** Infrastructure deployed and verified. The Application Load Balancer returns HTTP 200, and the two application instances have passed their target health checks. Application-to-database integration has not yet been implemented or tested.

## Table of Contents

- [1. Project Overview](#1-project-overview)
- [2. Architecture](#2-architecture)
- [3. AWS Resources](#3-aws-resources)
- [4. Network and Traffic Flow](#4-network-and-traffic-flow)
- [5. Security Design](#5-security-design)
- [6. Repository Structure](#6-repository-structure)
- [7. Prerequisites](#7-prerequisites)
- [8. AWS Authentication and Permissions](#8-aws-authentication-and-permissions)
- [9. Remote Terraform State](#9-remote-terraform-state)
- [10. Deployment Guide](#10-deployment-guide)
- [11. Verification and Testing](#11-verification-and-testing)
- [12. Code Quality and Pre-Commit](#12-code-quality-and-pre-commit)
- [13. Troubleshooting](#13-troubleshooting)
- [14. Cost Considerations](#14-cost-considerations)
- [15. Cleanup and Resource Destruction](#15-cleanup-and-resource-destruction)
- [16. Current Limitations and Future Improvements](#16-current-limitations-and-future-improvements)
- [17. Contributing](#17-contributing)

---

## 1. Project Overview

This project provisions a three-tier infrastructure on Amazon Web Services (AWS) using Terraform.

The infrastructure is organized into three logical tiers:

1. **Web tier:** An internet-facing Application Load Balancer (ALB) receives HTTP requests.
2. **Application tier:** An EC2 Auto Scaling Group runs two EC2 instances in private application subnets.
3. **Database tier:** An Amazon RDS for PostgreSQL instance runs in private database subnets and accepts database traffic only from the application security group.

The infrastructure spans two Availability Zones to demonstrate a multi-AZ network layout and distribute application instances across separate zones.

### Project objectives

- Provision AWS resources declaratively with Terraform.
- Follow least-privilege principles for Terraform execution and EC2 IAM roles.
- Separate public, application, and database networking.
- Restrict traffic between tiers using security groups.
- Use an Application Load Balancer and Auto Scaling Group.
- Store Terraform state remotely in an encrypted, versioned S3 bucket.
- Use Terraform's S3 state locking mechanism.
- Run automated formatting and secret-detection checks before commits.
- Keep infrastructure costs lower by avoiding a NAT Gateway and using small instance types.

## 2. Architecture

### High-level architecture

```text
                         Internet
                            |
                            v
                +------------------------+
                |  Application Load      |
                |  Balancer (HTTP :80)   |
                +-----------+------------+
                            |
                  Public Subnets
                    /           \
                   /             \
                  v               v
          +---------------+ +---------------+
          | Application   | | Application   |
          | EC2 Instance  | | EC2 Instance  |
          | Private AZ A  | | Private AZ B  |
          +-------+-------+ +-------+-------+
                  \               /
                   \             /
                    v           v
               +--------------------+
               | RDS PostgreSQL     |
               | Private DB Subnets |
               +--------------------+
```

The diagram shows the logical traffic flow. The ALB occupies the public subnets, the EC2 instances occupy the application subnets, and RDS uses the database subnet group.

The database is provisioned, but the demonstration web server does not currently connect to it.

### Network layout

The VPC uses the IPv4 CIDR `10.0.0.0/16` and contains six subnets across two Availability Zones.

| Tier | Subnet | CIDR |
|---|---|---|
| Public | `public_a` | `10.0.1.0/24` |
| Public | `public_b` | `10.0.2.0/24` |
| Application | `app_a` | `10.0.11.0/24` |
| Application | `app_b` | `10.0.12.0/24` |
| Database | `db_a` | `10.0.21.0/24` |
| Database | `db_b` | `10.0.22.0/24` |

The actual Availability Zone names are selected by AWS data sources. The suffixes `a` and `b` are logical labels and do not guarantee particular physical Availability Zone names.

## 3. AWS Resources

The project provisions the following resources.

| Resource | Purpose |
|---|---|
| Amazon VPC | Provides isolated network addressing. |
| Six subnets | Separates public, application, and database tiers across two AZs. |
| Internet Gateway | Provides internet routing for the public subnets. |
| Route tables and associations | Define subnet routing. |
| Three security groups | Restrict ALB, application, and database traffic. |
| Application Load Balancer | Receives external HTTP traffic and forwards requests to registered targets. |
| ALB listener and target group | Forward requests to EC2 instances and check application health. |
| EC2 launch template | Defines the AMI, instance type, IAM profile, security group, disk, metadata options, and user data. |
| Auto Scaling Group | Maintains two application instances. |
| IAM role and instance profile | Provide an identity for EC2 without requiring static AWS credentials. |
| RDS PostgreSQL | Provides a managed relational database. |
| RDS DB subnet group | Places the database in the private database subnet tier. |
| S3 state bucket | Stores Terraform state remotely, with versioning and encryption. |

### Main configuration choices

| Setting | Value |
|---|---|
| AWS region | `us-east-1` |
| EC2 instance type | `t3.micro` |
| ASG desired/minimum/maximum | `2 / 2 / 2` |
| AMI | Latest matching Amazon Linux 2023 x86-64 EBS-backed image at plan time |
| Application port | TCP `80` |
| Database engine | PostgreSQL 17 |
| Database instance class | `db.t4g.micro` |
| Database storage | 20 GB gp3, encrypted |
| Database public accessibility | Disabled |
| RDS Multi-AZ deployment | Disabled to reduce cost |
| NAT Gateway | Not provisioned |
| Application protocol | HTTP |

The exact AMI ID is resolved by a Terraform data source. It may change when a newer matching image becomes available.

## 4. Network and Traffic Flow

### Internet to application

1. A client sends an HTTP request to the ALB DNS name.
2. The ALB security group permits inbound TCP port 80 from the internet.
3. The ALB listener forwards the request to the target group.
4. The target group sends traffic to a healthy EC2 instance on TCP port 80.
5. The application security group permits this traffic only when its source is the ALB security group.

### Application to database

The database security group permits inbound TCP port 5432 only from the application security group.

This allows application-tier resources with the appropriate security-group membership to establish PostgreSQL connections, subject to routing, database availability, and database authentication.

The current demonstration does not yet establish or verify an actual application-to-database connection.

### Routing and private subnet access

The public route table routes internet-bound traffic through the Internet Gateway.

The application and database subnets do not have a default route through a NAT Gateway. This is an intentional cost-conscious design choice.

**Important:** Private subnet placement and security-group rules do not, by themselves, provide internet connectivity. Without an appropriate route, a NAT Gateway, or a suitable VPC endpoint, private instances cannot access external services through the internet.

A NAT Gateway can be added if private instances need outbound internet access, but it introduces additional hourly and data-processing charges. A VPC endpoint may be a more appropriate option for supported AWS services such as S3.

## 5. Security Design

### 5.1 Security group rules

| Security group | Inbound traffic | Outbound traffic |
|---|---|---|
| ALB | TCP 80 from `0.0.0.0/0` | All outbound traffic |
| Application | TCP 80 from the ALB security group | All outbound traffic |
| Database | TCP 5432 from the application security group | All outbound traffic |

The outbound rules are intentionally broad in this learning configuration. They can be tightened further according to the application's actual dependencies.

Security groups are stateful. Response traffic for an allowed connection is automatically permitted. Outbound security-group rules do not create routes or guarantee network connectivity.

### 5.2 IAM least privilege

The project uses separate IAM identities for infrastructure provisioning and application runtime.

**Terraform execution role**

Terraform assumes a dedicated role through AWS CLI credentials. The role's customer-managed policy grants the permissions needed to manage the project's infrastructure, including scoped IAM permissions for creating the EC2 role and instance profile.

The Terraform execution role should not receive unrestricted administrator permissions simply to resolve individual access-denied errors.

**EC2 runtime role**

The EC2 role is attached through an instance profile. It currently has no additional AWS service permissions because the demonstration web server does not need to call AWS APIs.

If the application later accesses S3, Secrets Manager, or another AWS service, grant only the specific permissions required.

### 5.3 EC2 metadata protection

The launch template requires IMDSv2:

- `http_tokens = "required"`

This prevents instances from using IMDSv1 to retrieve instance metadata.

### 5.4 Storage and state protection

- EC2 root volumes use encrypted gp3 storage.
- RDS storage encryption is enabled.
- The remote state S3 bucket has versioning, encryption, and S3 Block Public Access enabled.
- The S3 backend uses `encrypt = true` and `use_lockfile = true`.
- Local Terraform state, variable files, environment files, and provider configuration files are excluded through `.gitignore`.
- Gitleaks runs as part of pre-commit checks.

**Sensitive values still require protection.** Terraform state can contain database credentials and other sensitive values even when variables are marked `sensitive = true`. Restrict access to the state bucket and its versions, and never commit actual `.tfvars` files or state files to Git.

### 5.5 Current security limitations

This project is a learning environment, not a complete production deployment. It currently uses HTTP, has no domain or TLS certificate, and uses broad outbound security-group rules. Production use would require additional hardening.

## 6. Repository Structure

```text
terraform-aws-3tier-app/
├── bootstrap/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
├── .gitignore
├── .pre-commit-config.yaml
├── versions.tf
├── provider.tf
├── vpc.tf
├── subnets.tf
├── internet_gateway.tf
├── route_tables.tf
├── security_groups.tf
├── iam.tf
├── alb.tf
├── launch_template.tf
├── autoscaling.tf
├── rds.tf
├── variables.tf
├── outputs.tf
└── README.md
```

This is the intended logical organization. Filenames in the `bootstrap/` directory should be adjusted to match the files actually present in the repository.

### Key files

| File | Responsibility |
|---|---|
| `versions.tf` | Pins the Terraform and AWS provider version constraints and configures the S3 backend. |
| `provider.tf` | Configures the AWS provider. |
| `vpc.tf` | Defines the VPC. |
| `subnets.tf` | Defines the six subnets. |
| `internet_gateway.tf` | Defines the Internet Gateway. |
| `route_tables.tf` | Defines route tables and subnet associations. |
| `security_groups.tf` | Defines tier-specific security groups. |
| `iam.tf` | Defines the EC2 role and instance profile. |
| `alb.tf` | Defines the ALB, listener, and target group. |
| `launch_template.tf` | Defines the EC2 launch template and user data. |
| `autoscaling.tf` | Defines the Auto Scaling Group. |
| `rds.tf` | Defines PostgreSQL and its DB subnet group. |
| `variables.tf` | Defines configurable input variables. |
| `outputs.tf` | Exposes useful infrastructure outputs. |
| `bootstrap/` | Contains the separate configuration for creating the remote-state bucket. |
| `.pre-commit-config.yaml` | Defines local code-quality and secret-detection hooks. |
| `.gitignore` | Excludes local files and generated artifacts. |

## 7. Prerequisites

Install and configure the following tools on your workstation:

- [Terraform](https://developer.hashicorp.com/terraform/install)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [Git](https://git-scm.com/downloads)
- Python and the Python Launcher on Windows, if using the `py` commands below
- The Python `pre-commit` package

Verify the tools:

```powershell
terraform version
aws --version
git --version
py --version
py -m pre_commit --version
```

Use Terraform `1.16.x` and an AWS provider version compatible with the constraints in `versions.tf`. The committed `.terraform.lock.hcl` should be used to keep provider selections reproducible.

### AWS account requirements

You need an AWS account and credentials authorized to provision the resources in this project. Required permissions include networking, EC2, Elastic Load Balancing, Auto Scaling, RDS, and the scoped IAM operations used by the configuration.

The S3 backend bucket must exist before initializing the root configuration with the remote backend.

## 8. AWS Authentication and Permissions

The root AWS provider uses the standard AWS credential chain and specifies the region in the provider configuration. It does not hardcode AWS access keys or a profile name.

The original setup uses these AWS CLI profiles:

- `terraform-dev` — authenticates the user.
- `terraform-project1` — assumes the dedicated `TerraformProject1Role`.

These names are specific to the original local environment. Configure equivalent profiles for your own account.

### Authenticate

```powershell
aws login --profile terraform-dev
```

Check the assumed identity:

```powershell
aws sts get-caller-identity --profile terraform-project1
```

Confirm that the returned account and role identity are the ones you intend to use.

### Export temporary role credentials for Terraform

In the original Windows PowerShell workflow:

```powershell
$credentials = aws configure export-credentials `
  --profile terraform-project1 `
  --format process |
  ConvertFrom-Json

if (-not $credentials.AccessKeyId -or
    -not $credentials.SecretAccessKey -or
    -not $credentials.SessionToken) {
    throw "Temporary credentials were not retrieved. Stop here."
}

$env:AWS_ACCESS_KEY_ID     = $credentials.AccessKeyId
$env:AWS_SECRET_ACCESS_KEY = $credentials.SecretAccessKey
$env:AWS_SESSION_TOKEN     = $credentials.SessionToken
$env:AWS_DEFAULT_REGION    = "us-east-1"

Remove-Variable credentials

Write-Host "Temporary credentials loaded."
```

These are temporary credentials loaded into the current PowerShell session. They are not written into Terraform configuration files.

Do not commit credentials, terminal exports containing secrets, `.tfvars` files with real values, or state files.

## 9. Remote Terraform State

The root configuration stores state in an S3 backend.

The original project uses the following settings:

| Setting | Value |
|---|---|
| Bucket | `terraform-aws-3tier-app-state-949049116271` |
| Region | `us-east-1` |
| State key | `terraform-aws-3tier-app/terraform.tfstate` |
| Encryption | Enabled |
| Bucket versioning | Enabled |
| S3 Block Public Access | Enabled |
| State locking | S3 lockfile |

The bucket name contains the original AWS account ID. For your own deployment, replace it with a globally unique bucket name owned by your account.

### Why remote state?

Remote state provides centralized storage for Terraform's resource mapping and metadata. Versioning can help recover earlier state versions, and the S3 lockfile mechanism helps prevent concurrent Terraform operations from modifying the same state simultaneously.

Encryption, versioning, locking, and public-access blocking serve different purposes; none replaces restrictive IAM and bucket policies.

### Bootstrap configuration

The `bootstrap/` configuration creates the state bucket and its foundational security settings.

The bootstrap configuration has a separate local state file in the original setup. Do not run the bootstrap configuration from the root directory or confuse its state with the application infrastructure state.

If the remote-state bucket already exists, do not recreate it. If you are building a new environment, inspect the bootstrap configuration and its example variables, initialize it in the `bootstrap/` directory, review the plan, and apply it before initializing the root configuration.

**Do not destroy the bootstrap bucket while the root Terraform state still depends on it.**

## 10. Deployment Guide

### Step 1: Clone the repository

```powershell
git clone https://github.com/RaoSharifMansoob/terraform-aws-3tier-app.git
Set-Location terraform-aws-3tier-app
```

### Step 2: Configure variables

Review `variables.tf` and `terraform.tfvars.example`.

Create your local variable file:

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and provide the values required by your configuration, including the database password.

Keep the actual `terraform.tfvars` file local and untracked. The example file should contain safe placeholders, never real passwords or credentials.

### Step 3: Authenticate to AWS

Follow the authentication procedure in [Section 8](#8-aws-authentication-and-permissions).

Verify the identity and ensure the temporary credentials are available to Terraform.

### Step 4: Initialize Terraform

From the repository root:

```powershell
terraform init
```

This initializes the backend and downloads the required provider packages. If you change backend settings, Terraform may require reinitialization.

### Step 5: Run code-quality checks

```powershell
py -m pre_commit run --all-files
```

Fix any reported issues and stage files again if the hooks modify them.

### Step 6: Validate the configuration

```powershell
terraform validate
```

Validation checks the configuration for syntax and internal consistency. It does not prove that AWS permissions are sufficient or that all resources can be created.

### Step 7: Review the execution plan

```powershell
terraform plan
```

Review the proposed changes carefully. Confirm the AWS account, region, instance sizes, database configuration, and expected costs before proceeding.

### Step 8: Apply the configuration

Only after reviewing the plan:

```powershell
terraform apply
```

Confirm the operation when prompted.

Do not use automatic approval in an unfamiliar environment before reviewing the plan.

### Step 9: Retrieve outputs

```powershell
terraform output
```

The configuration exposes outputs including the VPC ID, ALB DNS name and URL, security group IDs, and RDS endpoint information.

The RDS endpoint is an address, not a database password. Its availability does not mean the database is publicly accessible.

## 11. Verification and Testing

### Verify Terraform state against AWS

```powershell
terraform validate
terraform plan
```

After a successful deployment, a no-change plan should report that the infrastructure matches the configuration, assuming no out-of-band changes have occurred.

### Test the ALB

Retrieve the URL:

```powershell
terraform output -raw alb_url
```

Then test it:

```powershell
$url = terraform output -raw alb_url
Invoke-WebRequest -Uri $url -UseBasicParsing
```

The demonstration server should return HTTP `200 OK` with:

```text
Hello from Terraform!
```

The ALB uses HTTP and does not currently have TLS configured.

### Check target health

Retrieve the target group ARN from Terraform state:

```powershell
$targetGroupArn = terraform state show aws_lb_target_group.app |
    Select-String 'arn\s*=' |
    ForEach-Object { ($_ -split '=', 2)[1].Trim().Trim('"') }
```

Then check target health:

```powershell
aws elbv2 describe-target-health `
  --target-group-arn $targetGroupArn `
  --profile terraform-project1 `
  --query "TargetHealthDescriptions[*].[Target.Id,TargetHealth.State,TargetHealth.Reason]" `
  --output table
```

Both application instances should normally be `healthy` after initialization. During replacement or deployment, temporary `initial`, `draining`, or unhealthy states may occur.

### Check the Auto Scaling Group

```powershell
aws autoscaling describe-auto-scaling-groups `
  --auto-scaling-group-names terraform-3tier-asg `
  --profile terraform-project1 `
  --query "AutoScalingGroups[0].[DesiredCapacity,MinSize,MaxSize,Instances[*].[InstanceId,LifecycleState,HealthStatus]]" `
  --output json
```

The desired state is two healthy instances in service.

### Database verification

RDS is provisioned as a private PostgreSQL database. A complete application-to-database integration test remains future work.

For an eventual database test, verify DNS resolution, routing, security-group rules, database status, credentials, and the database port from an authorized host in the VPC. Do not make RDS publicly accessible just to simplify testing.

## 12. Code Quality and Pre-Commit

The repository uses pre-commit to run local checks before Git creates a commit.

Configured hooks include:

| Hook | Purpose |
|---|---|
| `check-yaml` | Checks YAML files for basic validity. |
| `end-of-file-fixer` | Ensures files end with a newline. |
| `trailing-whitespace` | Removes trailing whitespace. |
| `terraform_fmt` | Formats Terraform files. |
| `gitleaks` | Detects potential hardcoded secrets. |

### Install the Git hook

After cloning the repository:

```powershell
py -m pip install pre-commit
py -m pre_commit install
```

### Run checks manually

```powershell
py -m pre_commit run --all-files
```

This checks all applicable tracked files. Git also invokes the installed hook automatically when you run `git commit`.

### Recommended Git workflow

```powershell
git status
py -m pre_commit run --all-files
terraform validate
terraform plan
git add .
git status
git commit -m "Describe your changes"
git push origin main
```

Always review the plan before applying infrastructure changes. Pre-commit checks do not replace Terraform validation, plan review, or CI/CD security controls.

## 13. Troubleshooting

### AWS provider fails to start or crashes

If `terraform validate` reports a provider schema error, check the full error. An out-of-memory provider crash is different from a Terraform syntax error.

- Check available RAM and virtual memory.
- Close unnecessary applications.
- Retry after addressing memory pressure.
- Keep the committed `.terraform.lock.hcl` unless there is a specific reason to change provider versions.

### Access denied during apply

Check the active AWS identity:

```powershell
aws sts get-caller-identity --profile terraform-project1
```

Confirm the assumed role and review the specific denied action and resource ARN. Add only the narrowly scoped permissions required for the operation; avoid granting broad administrator access to the Terraform execution role as a workaround.

### ALB returns 502 or targets are unhealthy

Check:

- Target group health status and reason.
- EC2 instance lifecycle and Auto Scaling health.
- Application security-group inbound rules.
- Whether the server is listening on port 80.
- Whether user data completed successfully.

This project's private application subnets do not have NAT-based internet access. Startup scripts that require downloading operating-system packages may fail unless the required network path or package source is available.

### Pre-commit modifies files and the commit fails

Run:

```powershell
py -m pre_commit run --all-files
git add .
git status
git commit -m "Describe your changes"
```

If a hook modifies files, stage the modifications before retrying the commit.

### Terraform proposes unexpected changes

Do not immediately apply them. Review the plan, inspect the affected resource configuration, and verify that the correct backend, workspace, account, region, and variables are being used.

## 14. Cost Considerations

This is a learning environment, not a zero-cost deployment.

Potential charges include:

- Application Load Balancer hourly and capacity-related usage.
- Two running EC2 instances and their EBS volumes.
- RDS instance-hours and allocated database storage.
- S3 storage, requests, and stored object versions.
- Data transfer and any additional AWS services enabled later.

The configuration avoids a NAT Gateway and uses small instance sizes to reduce cost. RDS is not Multi-AZ, and the Auto Scaling Group is fixed at two instances.

Actual prices depend on region, usage, current AWS pricing, and applicable free-tier eligibility. Review the [AWS Pricing Calculator](https://calculator.aws/) before deploying and check AWS billing after deployment.

**Important:** Resources continue to incur charges while they exist, even when you are not actively testing the application.

## 15. Cleanup and Resource Destruction

When finished, remove the application infrastructure if you no longer need it.

### Step 1: Confirm the correct environment

Ensure you are in the repository root and authenticated to the intended AWS account and role.

### Step 2: Review the destruction plan

```powershell
terraform plan -destroy
```

Inspect the resources that Terraform proposes to delete. Confirm that the plan does not target shared resources you need to retain.

### Step 3: Destroy the application infrastructure

```powershell
terraform destroy
```

Review the prompt before confirming.

The root configuration is designed to remove the application resources it manages. Destruction is irreversible for resources and data that are not recoverable, and this configuration currently skips a final RDS snapshot.

**Back up any database data you need before destroying the database.**

### Step 4: Preserve the state backend

The S3 state bucket is managed separately through the bootstrap configuration. Do not destroy it as part of ordinary application cleanup.

Retaining the bucket preserves the remote state and its version history. If you later decide to remove the backend, first confirm that no active Terraform state depends on it and plan a deliberate state-migration or archival procedure.

## 16. Current Limitations and Future Improvements

The current scope prioritizes a straightforward, understandable infrastructure foundation.

Potential future improvements include:

- HTTPS using ACM and an appropriate domain name.
- A production application server and a real application deployment pipeline.
- Actual application-to-RDS connectivity and integration tests.
- More restrictive outbound security-group rules.
- Monitoring, logging, alarms, and operational dashboards.
- Automated security and infrastructure checks in CI/CD.
- A managed approach for application secrets.
- A deliberate backup, recovery, and database-retention strategy.
- A NAT Gateway or selected VPC endpoints if future application requirements need outbound connectivity.
- Separate development and production environments when the project scope grows.

These are possible extensions, not features that the current configuration claims to have implemented.

## 17. Contributing

Contributions and suggestions are welcome.

1. Fork the repository.
2. Create a feature branch.
3. Make focused changes.
4. Run `py -m pre_commit run --all-files`.
5. Run `terraform validate` and review `terraform plan`.
6. Open a pull request explaining the change and its security or cost implications.

Never submit AWS credentials, database passwords, Terraform state files, or other sensitive information.
