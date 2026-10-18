# twk-infra

Terraform configuration for the **twk** development environment on AWS. This repo provisions a simple network (VPC, subnet, IGW, route table), a secure EC2 dev instance with an attached EBS data volume and static Elastic IP, and an S3 bucket configured for state/versioning/encryption. SSH access is restricted to a single source IP.

## What it creates

- **VPC** (`aws_vpc.twk`): CIDR `10.60.0.0/16` (DNS enabled), marked `prevent_destroy`
- **Internet Gateway + public subnet**: IGW attached to VPC; `dev` subnet in AZ `eu-west-1a` with public IPs on launch
- **Route table**: routes `0.0.0.0/0` to IGW and associates to the dev subnet
- **Security group** (`twk-sg-dev`): allows SSH (22) from `var.ssh_cidr` only; HTTP (80) and HTTPS (443) from anywhere (`0.0.0.0/0`); all egress allowed. Uses VPC security group ingress/egress rules (AWS provider >= 5.0).
- **EC2 instance** (`twk-dev`): Ubuntu 22.04 (Jammy) AMI (most recent from Canonical), `t3.xlarge` by default (configurable), in `eu-west-1a`, attached to dev SG/subnet, root EBS gp3 40 GB encrypted, IMDSv2 required (`http_tokens = "required"`). `prevent_destroy = true`, `ignore_changes = [ami]`.
- **Data disk**: EBS gp3 100 GB encrypted, attached at `/dev/sdf`, also `prevent_destroy = true`.
- **Elastic IP**: VPC EIP allocated and associated to the EC2 instance (depends on IGW).
- **S3 state bucket** (`var.s3_bucket_name`): versioning enabled, all public access blocked, server-side encryption (AES256). `prevent_destroy = true`.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.5.0 (see `versions.tf`)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) configured with credentials that can create/manage the above resources (VPC, EC2, EBS, EIP, S3). The IAM principal needs permissions to provision these resources.
- An SSH public key you control (for `ssh_public_key`).
- A globally unique S3 bucket name (for `s3_bucket_name`).
- Your public IP in CIDR form for SSH access (e.g. `203.0.113.10/32`).

## File layout

- `versions.tf` - Terraform and provider version constraints
- `provider.tf` - AWS provider configuration (uses `var.aws_region`)
- `variables.tf` - All configurable inputs with defaults
- `terraform.tfvars` - Example values for variables (not committed secrets; review and adjust)
- `network.tf` - VPC, IGW, subnet, route table, security group/rules
- `ec2.tf` - AMI lookup, key pair, EC2, EBS data volume, attachments, EIP
- `s3.tf` - S3 bucket for state with versioning, public access block, encryption
- `outputs.tf` - Useful outputs (IDs, IPs, bucket name)
- `.gitignore` - Ignores tfstate files, `.terraform/`, `tfplan`, etc. (commits `.terraform.lock.hcl`)
- `tfplan` - A plan file present in the repo (already generated)

## Configuration

Edit `terraform.tfvars` (or override via `-var` flags) with your values. Required/important variables:

| Variable | Description | Default |
|---|---|---|
| `aws_region` | AWS region | `eu-west-1` |
| `az` | Availability zone | `eu-west-1a` |
| `env_prefix` | Name prefix for resources | `twk` |
| `vpc_cidr` | VPC CIDR block | `10.60.0.0/16` |
| `dev_subnet_cidr` | Dev subnet CIDR | `10.60.2.0/24` |
| `instance_name` | EC2 instance name tag | `twk-dev` |
| `instance_type` | EC2 instance type. `t3.xlarge` (4 vCPU/16 GB) recommended; alternatives `m5.xlarge`, `t3.large` | `t3.xlarge` |
| `ami_name_filter` | AMI name filter for Ubuntu 22.04 | `ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*` |
| `system_disk_size` | Root disk size (GB) | `40` |
| `data_disk_size` | Data disk size (GB) | `100` |
| `ssh_cidr` | Source CIDR allowed for SSH (e.g. `203.0.113.10/32`) | **required** (no default) |
| `ssh_key_name` | SSH key pair name in AWS | `twk-dev-key` |
| `ssh_public_key` | Public SSH key content | **required** (no default) |
| `s3_bucket_name` | Globally unique S3 bucket name for state | **required** (no default) |
| `tags` | Common tags applied to resources | `{project="twk", env="dev", managed-by="terraform"}` |

> Security note: only commit non-sensitive values. `ssh_public_key` is safe; never commit private keys. `.gitignore` already excludes `*.tfstate`, `*.tfvars` (if you want), `tfplan`, etc. Check what you actually commit.

## Usage

Typical workflow:

```bash
# Initialize Terraform (downloads providers)
terraform init

# Validate configuration
terraform validate

# Review what will be created/changed
terraform plan -out=tfplan

# Apply the plan
terraform apply tfplan
# or just terraform apply if you prefer
```

After apply, you can inspect outputs:

```bash
terraform output
```

Connect via SSH (note: SSH is restricted to `ssh_cidr` only):

```bash
ssh -i /path/to/your/private-key ubuntu@<ec2_public_ip>
```

The data disk is attached as `/dev/sdf`. Depending on OS, you may need to format/mount it (first boot).

## Notes on safety

- Several resources have `prevent_destroy = true` (VPC, EC2, EBS, S3 bucket). If you need to destroy, remove or change that lifecycle block first.
- AMI is set with `ignore_changes = [ami]` to avoid replacement when newer Ubuntu AMIs are published.
- S3 bucket is configured with versioning, public access block, and SSE-AES256.
- SSH access is strictly limited to the CIDR you specify.

## Cleanup

Destroying will remove all resources unless lifecycle protections prevent it. To fully destroy (if protections removed): 

```bash
terraform destroy
```

Be cautious - this permanently deletes the infrastructure. 

If you keep `prevent_destroy = true`, Terraform will refuse to destroy those resources. 
