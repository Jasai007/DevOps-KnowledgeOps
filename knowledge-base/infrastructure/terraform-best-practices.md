# Terraform Best Practices

## Project Structure and Organization

### Recommended Directory Structure
```
terraform/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   └── outputs.tf
│   ├── staging/
│   └── prod/
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── eks/
│   ├── rds/
│   └── s3/
├── shared/
│   ├── backend.tf
│   └── provider.tf
└── scripts/
    ├── deploy.sh
    └── destroy.sh
```

### Module Design Principles

#### 1. Single Responsibility
Each module should have a single, well-defined purpose:
```hcl
# Good: VPC module focuses only on networking
module "vpc" {
  source = "./modules/vpc"
  
  cidr_block           = var.vpc_cidr
  availability_zones   = var.azs
  enable_nat_gateway   = var.enable_nat
  enable_vpn_gateway   = false
}

# Avoid: Mixing concerns in one module
```

#### 2. Composable Modules
Design modules to work together:
```hcl
module "vpc" {
  source = "./modules/vpc"
  # VPC configuration
}

module "eks" {
  source = "./modules/eks"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
}
```

## State Management

### Remote State Configuration
Always use remote state for team collaboration:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "environments/prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-locks"
  }
}
```

### State Locking
Implement state locking to prevent concurrent modifications:

```hcl
resource "aws_dynamodb_table" "terraform_locks" {
  name           = "terraform-state-locks"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "Terraform State Locks"
  }
}
```

## Variable Management

### Variable Hierarchy
Use a clear variable hierarchy:

1. **terraform.tfvars** - Environment-specific values
2. **variables.tf** - Variable definitions with defaults
3. **Environment variables** - Sensitive values

```hcl
# variables.tf
variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

# terraform.tfvars
environment   = "prod"
instance_type = "t3.large"
```

### Sensitive Variables
Handle sensitive data properly:

```hcl
variable "database_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

# Use AWS Secrets Manager or Parameter Store
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "prod/database/password"
}
```

## Resource Naming and Tagging

### Consistent Naming Convention
```hcl
locals {
  name_prefix = "${var.project}-${var.environment}"
  
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = var.team_name
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-web-server"
    Type = "web-server"
  })
}
```

## Security Best Practices

### IAM Policies
Use least privilege principle:

```hcl
data "aws_iam_policy_document" "s3_policy" {
  statement {
    effect = "Allow"
    
    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]
    
    resources = [
      "${aws_s3_bucket.app_bucket.arn}/*"
    ]
    
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["AES256"]
    }
  }
}
```

### Encryption
Enable encryption by default:

```hcl
resource "aws_s3_bucket" "app_bucket" {
  bucket = "${local.name_prefix}-app-data"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app_bucket" {
  bucket = aws_s3_bucket.app_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "app_bucket" {
  bucket = aws_s3_bucket.app_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

## Code Quality and Testing

### Validation Rules
Add validation to prevent common mistakes:

```hcl
variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access resources"
  type        = list(string)
  
  validation {
    condition = alltrue([
      for cidr in var.allowed_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All CIDR blocks must be valid."
  }
}
```

### Pre-commit Hooks
Use tools like `terraform fmt`, `terraform validate`, and `tflint`:

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.77.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_tflint
      - id: terraform_docs
```

### Testing Strategy
Implement multiple testing layers:

1. **Unit Tests**: Test individual modules
2. **Integration Tests**: Test module interactions
3. **End-to-End Tests**: Test complete infrastructure

```go
// Example using Terratest
func TestVPCModule(t *testing.T) {
    terraformOptions := &terraform.Options{
        TerraformDir: "../modules/vpc",
        Vars: map[string]interface{}{
            "cidr_block": "10.0.0.0/16",
        },
    }

    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)

    vpcId := terraform.Output(t, terraformOptions, "vpc_id")
    assert.NotEmpty(t, vpcId)
}
```

## Performance Optimization

### Parallel Execution
Optimize for parallel execution:

```hcl
# Use depends_on sparingly - let Terraform infer dependencies
resource "aws_security_group" "web" {
  name_prefix = "${local.name_prefix}-web"
  vpc_id      = aws_vpc.main.id
  # Terraform automatically knows this depends on the VPC
}

# Explicit dependency only when necessary
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  
  depends_on = [aws_internet_gateway.main]
}
```

### Resource Lifecycle Management
```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  
  lifecycle {
    create_before_destroy = true
    ignore_changes       = [ami]
  }
}
```

## Multi-Environment Management

### Workspace Strategy
```bash
# Create workspaces for environments
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Use workspace in configuration
locals {
  environment = terraform.workspace
  
  instance_counts = {
    dev     = 1
    staging = 2
    prod    = 5
  }
}

resource "aws_instance" "web" {
  count         = local.instance_counts[local.environment]
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
}
```

### Environment-Specific Configurations
```hcl
# Use locals for environment-specific values
locals {
  environment_configs = {
    dev = {
      instance_type = "t3.micro"
      min_size     = 1
      max_size     = 2
    }
    prod = {
      instance_type = "t3.large"
      min_size     = 3
      max_size     = 10
    }
  }
  
  config = local.environment_configs[var.environment]
}
```

## Monitoring and Maintenance

### Resource Drift Detection
```bash
# Regular drift detection
terraform plan -detailed-exitcode

# Automated drift detection in CI/CD
if terraform plan -detailed-exitcode; then
  echo "No drift detected"
else
  echo "Drift detected - review changes"
fi
```

### Documentation
Use terraform-docs for automatic documentation:

```bash
# Generate documentation
terraform-docs markdown table --output-file README.md .
```

### Version Pinning
Pin provider versions for consistency:

```hcl
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```