# Terraform AWS 3-Tier Application

A secure, modular, and cost-conscious AWS 3-tier application infrastructure provisioned using Terraform. This project demonstrates Infrastructure as Code (IaC), reusable Terraform modules, environment separation, network security, load balancing, auto scaling, and remote state management.

Both **Dev and Prod environments are implemented and tested successfully**. They use the same reusable Terraform modules and infrastructure code, while environment-specific variables allow their configurations to be managed independently.

## Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [AWS Infrastructure](#aws-infrastructure)
- [Amazon Machine Image (AMI)](#amazon-machine-image-ami)
- [Repository Structure](#repository-structure)
- [Environment Management](#environment-management)
- [Remote State Management](#remote-state-management)
- [Security Design](#security-design)
- [Prerequisites](#prerequisites)
- [Deployment Guide](#deployment-guide)
- [Verification](#verification)
- [Pre-commit and Code Quality](#pre-commit-and-code-quality)
- [Cost Considerations and Cleanup](#cost-considerations-and-cleanup)
- [Current Limitations](#current-limitations)
- [Future Improvements](#future-improvements)

## Project Overview

The purpose of this project is to provision and manage a three-tier application infrastructure on AWS using Terraform.

The infrastructure separates the public entry point, application instances, and database into distinct network tiers. Terraform modules provide reusable infrastructure components, while separate environment configurations allow Dev and Prod to use different CIDRs, instance configurations, capacity settings, and other parameters without duplicating the underlying infrastructure code.

### Key Features

- Modular Terraform architecture with reusable infrastructure components.
- Separate Dev and Prod environment configurations.
- Public Application Load Balancer (ALB).
- Private EC2 instances managed by an Auto Scaling Group (ASG).
- Private Amazon RDS for PostgreSQL.
- Custom security groups with tier-to-tier access restrictions.
- IAM instance roles and required IMDSv2 for EC2.
- Encrypted EBS and RDS storage.
- Amazon S3 remote state with versioning, encryption, and state locking.
- Ephemeral database password generation using Terraform.
- Pre-commit hooks for formatting and security checks.
- Configurable instance sizes and Auto Scaling capacity.

## Architecture

The infrastructure follows a three-tier architecture:

```text
                         Internet
                            |
                            v
                  Application Load Balancer
                       (Public Subnets)
                            |
                            v
                    EC2 Auto Scaling Group
                       (Private Subnets)
                            |
                            v
                    Amazon RDS PostgreSQL
                       (Private Subnets)
```

### Request Flow

1. Users access the application through the public Application Load Balancer.
2. The ALB forwards HTTP requests to healthy EC2 instances in the private application subnets.
3. The application tier is configured to communicate with the database tier through restricted security group rules.
4. RDS PostgreSQL is deployed in private database subnets and is not directly accessible from the internet.

The Dev and Prod environments use the same architectural pattern but maintain separate environment configurations and Terraform state.

## AWS Infrastructure

| Component | Purpose |
|---|---|
| Amazon VPC | Provides isolated networking for each environment. |
| Public subnets | Host the Application Load Balancer. |
| Private application subnets | Host EC2 instances managed by the ASG. |
| Private database subnets | Host RDS PostgreSQL. |
| Application Load Balancer | Distributes HTTP traffic across healthy application instances. |
| EC2 Launch Template | Defines the AMI, instance type, storage, and instance settings. |
| Auto Scaling Group | Maintains the configured instance capacity and replaces unhealthy instances. |
| Amazon RDS PostgreSQL | Provides a managed relational database. |
| IAM role and instance profile | Define the AWS permissions available to EC2 instances. |
| Security groups | Control traffic between the ALB, application, and database tiers. |
| Amazon S3 | Stores Terraform remote state separately for each environment. |

### Network Configuration

The VPC and subnet CIDRs are configured through environment-specific variables.

| Setting | Dev | Prod |
|---|---|---|
| VPC CIDR | `10.0.0.0/16` | `10.1.0.0/16` |
| Availability Zones | 2 | 2 |
| Public subnets | Configurable | Configurable |
| Private application subnets | Configurable | Configurable |
| Private database subnets | Configurable | Configurable |

The separate VPC CIDRs prevent address-space overlap between these environments.

### Compute Configuration

EC2 instance types and Auto Scaling capacity are configurable independently for each environment.

For example, the following settings control the Auto Scaling Group capacity:

- `min_size`: Minimum number of instances.
- `desired_capacity`: Target number of instances.
- `max_size`: Maximum number of instances.
- `instance_type`: EC2 instance size.
- `ami_id`: Image used to launch the instances.

These settings can be adjusted according to workload requirements, performance expectations, and budget. Production capacity should be selected based on workload testing and availability requirements rather than simply copying Dev settings.

### Database Configuration

The project uses Amazon RDS for PostgreSQL with the following configuration options:

- Database engine and version.
- Database instance class.
- Allocated storage and storage type.
- Storage encryption.
- Backup retention.
- Database name and username.
- Private subnet placement.
- Security group restrictions.

These settings are managed through Terraform variables and environment configuration.

## Amazon Machine Image (AMI)

An **Amazon Machine Image (AMI)** is a template used to launch EC2 instances. It defines the operating system and can include pre-installed software, configurations, and other components required by an application.

### Why Use an AMI?

- **Consistent deployments:** Instances launched by an Auto Scaling Group use a defined base image and configuration.
- **Faster provisioning:** Pre-installed software reduces the work required during instance startup.
- **Simplified scaling and recovery:** New instances can be launched with the required software when capacity increases or unhealthy instances are replaced.
- **Controlled environments:** A deliberately selected image provides a consistent foundation for security updates, maintenance, and application deployment.

### How the AMI Is Used in This Project

The AMI ID is supplied to the EC2 Launch Template. The Auto Scaling Group uses that template to launch EC2 instances in the private application subnets.

This project uses an image based on **Amazon Linux 2023 Minimal, x86-64**, with Nginx installed and enabled to serve a demonstration web page.

### AMI Selection Guidelines

When selecting an AMI:

- Choose an operating system that is supported and appropriate for the application.
- Verify the image publisher, architecture, and regional availability.
- Consider security updates, required packages, and application compatibility.
- Prefer a deliberately selected and tested image for repeatable deployments.
- Update the selected image through a controlled process when security patches or newer versions are needed.

AMI IDs are region-specific. The AMI selected for one AWS Region might not be available in another. Dev and Prod can use the same tested AMI or different image versions when their requirements justify it.

## Repository Structure

```text
terraform-aws-3tier-app/
├── bootstrap/
│   └── # Terraform configuration for bootstrapping remote state
│
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   ├── terraform.tfvars.example
│   │   ├── outputs.tf
│   │   └── versions.tf
│   │
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       ├── terraform.tfvars
│       ├── terraform.tfvars.example
│       ├── outputs.tf
│       └── versions.tf
│
├── modules/
│   ├── networking/
│   ├── security/
│   ├── load_balancer/
│   ├── compute/
│   └── database/
│
├── .pre-commit-config.yaml
├── .gitignore
└── README.md
```

The structure above describes the logical organization of the project. Each module contains the Terraform files required for its specific infrastructure component.

**Note:** `terraform.tfvars` files containing local environment values should remain untracked. Use the corresponding example files as templates.

## Environment Management

The project uses separate root configurations for Dev and Prod while sharing the same Terraform modules.

### How It Works

- Each environment has its own root Terraform configuration.
- Both environments call the same reusable modules.
- Environment-specific variable values determine CIDRs, resource names, instance types, capacity, database settings, and other configuration.
- Each environment has a separate remote-state key in the same S3 bucket.

This approach avoids duplicating the infrastructure implementation and makes it easier to maintain consistent security and architectural practices.

### Customizing an Environment

To change an environment's configuration, update the relevant values in its `terraform.tfvars` file or the appropriate variable defaults.

Examples include:

- Changing the VPC and subnet CIDRs.
- Selecting a different EC2 instance type.
- Adjusting the ASG minimum, desired, and maximum capacities.
- Selecting a different AMI.
- Changing the RDS instance class or storage configuration.

Always review the Terraform plan before applying changes, particularly when changing production resources. Some changes may cause resource replacement, downtime, or data loss.

## Remote State Management

Terraform state is stored remotely in Amazon S3. Both environments use the same state bucket but have different state keys.

| Environment | S3 state key |
|---|---|
| Dev | `terraform-aws-3tier-app/dev/terraform.tfstate` |
| Prod | `terraform-aws-3tier-app/prod/terraform.tfstate` |

The S3 bucket is configured with:

- Versioning to help recover previous state versions.
- Server-side encryption.
- S3 Block Public Access.
- Terraform state locking using `use_lockfile = true`.

### Why Separate State Keys?

Separate state keys ensure that Terraform tracks Dev and Prod resources independently. Operations in one environment should not inadvertently manage the resources tracked by the other environment's state.

Although the state is stored in the same bucket, **each environment must be initialized and operated on from its own directory**.

Remote state may contain sensitive infrastructure information. Restrict access to the S3 bucket and its state objects through appropriate IAM permissions.

## Security Design

Security is incorporated into the infrastructure through network isolation, access restrictions, encryption, and credential handling.

### Network Security

- The ALB is deployed in public subnets.
- EC2 application instances are deployed in private subnets.
- RDS is deployed in private database subnets.
- The application security group allows inbound HTTP traffic from the ALB security group.
- The database security group allows PostgreSQL traffic only from the application security group.
- The database is not publicly accessible.

### Compute Security

- EC2 instances use an IAM instance role and instance profile.
- IMDSv2 is required.
- EBS root volumes are encrypted.
- The Launch Template provides a consistent instance configuration.
- Access should follow the principle of least privilege.

### Database Security

- RDS storage is encrypted.
- Database traffic is restricted through security groups.
- The database is deployed in private subnets.
- Backup retention and deletion behavior are configurable.

### Database Password Handling

The project uses Terraform's ephemeral `random_password` resource and the AWS provider's write-only `password_wo` argument to avoid persisting the generated database password in Terraform state.

The password rotation version is controlled using `password_wo_version`. Increment this value when intentionally requesting a password update through Terraform.

**Important:** An ephemeral password is not a persistent secret store. The generated password is not available for later retrieval from Terraform state. A real application that needs to authenticate to the database requires an appropriate secure mechanism for delivering and managing database credentials. Production deployments should implement a deliberate secret lifecycle and recovery strategy.

### Terraform and Repository Security

- Sensitive values should not be committed to Git.
- `.gitignore` excludes local variable files and other generated or sensitive artifacts as appropriate.
- Gitleaks checks for potential hardcoded secrets.
- Terraform formatting and configuration checks run through pre-commit hooks.
- AWS access should use an appropriately scoped identity rather than routine root-account access.

## Prerequisites

Install the following tools before deploying the project:

- [Terraform](https://developer.hashicorp.com/terraform/install)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [Git](https://git-scm.com/downloads)
- [Python](https://www.python.org/downloads/)
- [pre-commit](https://pre-commit.com/)

The project was developed and tested using Terraform 1.16.6, AWS provider 6.69.1, and Random provider 3.7.2. The Terraform provider versions are declared in the environment configuration.

You also need an AWS identity with sufficient permissions to create the resources used by the selected environment and access the remote-state bucket.

## Deployment Guide

### 1. Clone the Repository

```powershell
git clone https://github.com/RaoSharifMansoob/terraform-aws-3tier-app.git
cd terraform-aws-3tier-app
```

### 2. Configure AWS Authentication

Authenticate using the AWS CLI profile configured for your project.

For example, if using AWS CLI login:

```powershell
aws login --profile terraform-dev
```

Verify the AWS identity and account associated with the profile used for deployment:

```powershell
aws sts get-caller-identity --profile terraform-project1
```

Use the profile that is configured and authorized for your selected environment. Ensure its credentials are valid before running Terraform.

### 3. Configure Environment Variables

Choose the environment you want to deploy.

For Dev:

```powershell
cd environments/dev
```

For Prod, start from the repository root and run:

```powershell
cd environments/prod
```

Create the local `terraform.tfvars` file using the environment's example file if it does not already exist. Configure the required values for the selected environment.

Review the VPC and subnet CIDRs, AMI, EC2 instance type, ASG capacity, database settings, and other resource parameters before proceeding.

### 4. Initialize Terraform

Run the following from the selected environment directory:

```powershell
terraform init
```

Terraform initializes the required providers and configures the S3 backend using that environment's state key.

If the backend configuration has changed, follow Terraform's documented backend migration or reconfiguration procedure rather than changing state paths casually.

### 5. Format and Validate

```powershell
terraform fmt -recursive
terraform validate
```

### 6. Review the Plan

```powershell
terraform plan -out=tfplan
```

Inspect the plan carefully to confirm that Terraform will create, update, or replace only the intended resources in the selected environment.

### 7. Apply the Configuration

```powershell
terraform apply tfplan
```

Apply only after reviewing the plan and confirming that the expected AWS resources and costs are acceptable.

### 8. Retrieve Outputs

Review the configured outputs:

```powershell
terraform output
```

If the environment exposes an ALB URL output, retrieve it with:

```powershell
terraform output -raw alb_url
```

The output name depends on the outputs defined in the selected environment.

Repeat the workflow from the other environment directory when you need to manage the other environment. Never assume that running Terraform in one directory automatically manages both environments.

## Verification

After deployment, verify that the infrastructure is functioning as expected.

### Application Access

If the environment exposes the ALB URL:

```powershell
$url = terraform output -raw alb_url
Invoke-WebRequest -Uri $url
```

A successful HTTP response indicates that the endpoint is reachable. For the current demonstration application, the response should contain the configured test page.

### Additional Checks

Verify that:

- The ALB target group reports the expected targets as healthy.
- The ASG has the intended minimum, desired, and maximum capacity.
- EC2 instances are launched in private application subnets.
- RDS is private and its security group permits access only from the application tier.
- The selected resources and network settings match the environment configuration.
- Dev and Prod state keys remain separate.

## Pre-commit and Code Quality

The repository uses pre-commit hooks to help maintain consistent Terraform code and identify common issues.

The configured checks include:

- YAML validation.
- End-of-file formatting.
- Trailing whitespace removal.
- Terraform formatting.
- Gitleaks secret detection.

Install the hooks from the repository root:

```powershell
py -m pre_commit install
```

Run all configured hooks manually:

```powershell
py -m pre_commit run --all-files
```

If a hook modifies a file, review the changes and stage the corrected files before committing.

## Cost Considerations and Cleanup

AWS resources may incur charges even when the application receives no traffic. Costs can come from the ALB, EC2 instances, RDS, storage, backups, and related services.

This project avoids NAT gateways to reduce costs, but the resulting network design limits outbound internet access from private instances unless an alternative egress mechanism is configured.

Before deploying, review the pricing of the selected resources and the capacity configured for each environment.

### Destroy an Environment

If an environment is no longer needed, change to its directory and review the destruction plan:

```powershell
terraform plan -destroy
```

If you are certain that the resources can be removed, destroy the environment:

```powershell
terraform destroy
```

Run these commands from the specific environment directory you intend to remove. Destroying an environment can permanently remove resources and data, so verify the selected environment and database retention requirements first.

Do not delete the shared S3 state bucket as part of routine environment cleanup. It contains state for both environments and may also contain state versions needed for recovery.

## Current Limitations

- The application is currently a demonstration web page rather than a complete database-backed application.
- The ALB serves HTTP; HTTPS and certificate management have not been implemented.
- NAT gateways and VPC endpoints are not configured.
- The ephemeral database password approach does not provide persistent credential retrieval or delivery to an application.
- Production monitoring, alerting, centralized logging, and a full CI/CD pipeline remain potential improvements.
- Production readiness requires workload testing, backup and recovery validation, capacity planning, and appropriate operational controls.

## Future Improvements

Potential enhancements include:

- Configure HTTPS using AWS Certificate Manager.
- Implement a secure, persistent database secret-management and rotation strategy.
- Connect a real application to PostgreSQL.
- Add CloudWatch monitoring, alarms, and centralized logging.
- Introduce automated Terraform plan checks and controlled deployment workflows.
- Improve outbound connectivity through an appropriate, cost-reviewed network design.
- Add tested backup restoration and disaster recovery procedures.
- Adopt controlled AMI updates and vulnerability scanning.
- Review production capacity, availability, and security requirements before handling real workloads.

## Project Principles

This project focuses on:

- **Infrastructure as Code:** Manage infrastructure through version-controlled Terraform.
- **Reusability:** Share modules between environments rather than duplicate resource definitions.
- **Environment separation:** Maintain distinct configurations and state for Dev and Prod.
- **Security by design:** Restrict network access, encrypt storage, and apply least privilege.
- **Cost awareness:** Make infrastructure choices with cost and operational requirements in mind.
- **Repeatability:** Use explicit configuration and validation to make deployments easier to understand and reproduce.
