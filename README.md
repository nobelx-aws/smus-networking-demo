# SMUS Networking Demo - Terraform

This Terraform configuration demonstrates how SageMaker Unified Studio network configuration changes are **forward-looking only** - existing projects stay in their original VPC while new projects use updated VPC settings.

## Demo Concept

**Key Insight**: When you change the VPC in a domain's tooling blueprint:
- ✅ New projects inherit the new VPC
- ❌ Existing projects stay in their original VPC
- ❌ Existing resources (Glue, EMR) are NOT migrated

## Architecture

### Initial State (enable_vpc_b = false)
```
Domain Tooling Blueprint → VPC-A
  └── Project-1 → VPC-A
      ├── Glue Connection → VPC-A
      └── EMR Cluster → VPC-A
```

### After Update (enable_vpc_b = true)
```
Domain Tooling Blueprint → VPC-B (UPDATED)
  ├── Project-1 → VPC-A (UNCHANGED!)
  │   ├── Glue Connection → VPC-A
  │   └── EMR Cluster → VPC-A
  └── Project-2 → VPC-B (NEW)
      ├── Glue Connection → VPC-B
      └── EMR Cluster → VPC-B
```

## Prerequisites

### 1. AWS Account Setup
- IAM permissions for DataZone, VPC, Glue, EMR
- AWS CLI configured

### 2. S3 Backend Setup
Create the S3 bucket and DynamoDB table for Terraform state:

```bash
# Create S3 bucket
aws s3 mb s3://smus-demo-terraform-state --region us-east-1
aws s3api put-bucket-versioning \
  --bucket smus-demo-terraform-state \
  --versioning-configuration Status=Enabled

# Create DynamoDB table
aws dynamodb create-table \
  --table-name smus-demo-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

Update `versions.tf` with your bucket and table names.

### 3. GitHub Setup

#### A. Create GitHub Repository
```bash
git init
git add .
git commit -m "Initial SMUS networking demo"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/smus-networking-demo.git
git push -u origin main
```

#### B. Configure AWS OIDC for GitHub Actions

1. **Create OIDC Provider** (one-time setup):
```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

2. **Create IAM Role** for GitHub Actions:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_USERNAME/smus-networking-demo:*"
        }
      }
    }
  ]
}
```

Attach policies: `AdministratorAccess` (or more restrictive policies for production)

3. **Add GitHub Secrets**:
   - Go to: Repository → Settings → Secrets and variables → Actions
   - Add:
     - `AWS_ROLE_ARN`: `arn:aws:iam::YOUR_ACCOUNT_ID:role/github-actions-role`
     - `AWS_REGION`: `us-east-1`

## Deployment Steps

### Step 1: Initial Deployment (Before Presentation)

1. **Copy and configure tfvars**:
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars - ensure enable_vpc_b = false
```

2. **Deploy locally** (test before presentation):
```bash
terraform init
terraform plan
terraform apply
```

3. **Verify outputs**:
```bash
terraform output demo_summary
```

You should see Project-1 in VPC-A.

4. **Commit and push** (triggers GitHub Actions):
```bash
git add .
git commit -m "Initial deployment with VPC-A"
git push origin main
```

### Step 2: Live Demo During Presentation

**During your presentation**, demonstrate the VPC change:

1. **Update the variable**:
```bash
# Edit terraform.tfvars
enable_vpc_b = true
```

2. **Commit and push** (live during presentation):
```bash
git add terraform.tfvars
git commit -m "Update to VPC-B - demonstrating forward-looking changes"
git push origin main
```

3. **Show GitHub Actions** running the deployment

4. **Display outputs** after deployment completes:
```bash
terraform output demo_summary
```

**Key Point to Highlight**: Project-1 resources stayed in VPC-A, only new Project-2 uses VPC-B!

## Verification Commands

After the update, verify VPC assignments:

```bash
# Show all outputs
terraform output -json

# Check Glue connections
aws glue get-connections --query 'ConnectionList[*].[Name,PhysicalConnectionRequirements.SubnetId]'

# Check EMR clusters
aws emr list-clusters --active --query 'Clusters[*].[Name,Id]'
aws emr describe-cluster --cluster-id <cluster-id> --query 'Cluster.Ec2InstanceAttributes.Ec2SubnetId'
```

## Cleanup

```bash
# Destroy all resources
terraform destroy

# Or via GitHub Actions (set enable_vpc_b = false first, then destroy)
```

## Troubleshooting

### Domain Creation Takes Too Long
- Domain creation takes 5-10 minutes
- **Solution**: Deploy initial state before presentation, only show the update live

### GitHub Actions Fails
- Check IAM role trust policy
- Verify GitHub secrets are set correctly
- Check CloudWatch Logs for detailed errors

### EMR Cluster Fails to Start
- Ensure subnets have internet access (NAT Gateway or VPC endpoints)
- Check security group rules
- Verify IAM instance profile permissions

## Cost Considerations

**Running costs**:
- EMR clusters: ~$0.50/hour (2 x m5.xlarge)
- VPCs/Subnets: Free
- DataZone domain: Varies by usage

**Recommendation**: Destroy resources immediately after demo to minimize costs.

## Presentation Tips

1. **Pre-deploy** the initial state (VPC-A + Project-1) before presentation
2. **During demo**: Only show the update (enable_vpc_b = true)
3. **Highlight**: Use `terraform output demo_summary` to clearly show VPC assignments
4. **Backup**: Have screenshots ready in case GitHub Actions is slow

## Files Structure

```
terraform-demo/
├── main.tf                    # Core infrastructure
├── variables.tf               # Input variables
├── outputs.tf                 # Output values with demo summary
├── versions.tf                # Provider and backend config
├── terraform.tfvars.example   # Example configuration
├── .gitignore                 # Git ignore patterns
├── .github/
│   └── workflows/
│       └── deploy.yml         # GitHub Actions workflow
└── README.md                  # This file
```

## Questions?

Contact: [Your contact info]
