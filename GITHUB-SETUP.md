# GitHub OIDC Setup Guide

This guide shows you how to configure GitHub Actions to deploy your Terraform code to AWS using OIDC (no access keys needed).

## Quick Setup (Automated)

Run the setup script:

```bash
cd terraform-demo
./setup-github-oidc.sh YOUR_GITHUB_USERNAME YOUR_REPO_NAME
```

Example:
```bash
./setup-github-oidc.sh nobelx smus-networking-demo
```

The script will:
1. Create the OIDC provider in AWS
2. Create an IAM role with trust policy for your GitHub repo
3. Attach necessary permissions
4. Display the values you need to add as GitHub secrets

## Manual Setup (Step-by-Step)

### Step 1: Create OIDC Provider

Run once per AWS account:

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

### Step 2: Create Trust Policy File

Replace `YOUR_ACCOUNT_ID`, `YOUR_USERNAME`, and `YOUR_REPO`:

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
          "token.actions.githubusercontent.com:sub": "repo:YOUR_USERNAME/YOUR_REPO:*"
        }
      }
    }
  ]
}
```

Save as `trust-policy.json`

### Step 3: Create IAM Role

```bash
aws iam create-role \
  --role-name github-actions-smus-demo \
  --assume-role-policy-document file://trust-policy.json \
  --description "Role for GitHub Actions to deploy SMUS demo"
```

### Step 4: Attach Permissions

```bash
aws iam attach-role-policy \
  --role-name github-actions-smus-demo \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

### Step 5: Get Role ARN

```bash
aws iam get-role \
  --role-name github-actions-smus-demo \
  --query Role.Arn \
  --output text
```

Copy the output (e.g., `arn:aws:iam::123456789012:role/github-actions-smus-demo`)

## Add GitHub Secrets

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add two secrets:

**Secret 1:**
- Name: `AWS_ROLE_ARN`
- Value: `arn:aws:iam::YOUR_ACCOUNT_ID:role/github-actions-smus-demo`

**Secret 2:**
- Name: `AWS_REGION`
- Value: `us-east-1`

## Verify Setup

Push a commit to trigger the workflow:

```bash
git add .
git commit -m "Test GitHub Actions"
git push origin main
```

Check the **Actions** tab in your GitHub repo to see the workflow run.

## Troubleshooting

### Error: "Not authorized to perform sts:AssumeRoleWithWebIdentity"

- Verify the trust policy has the correct GitHub username and repo name
- Check that the OIDC provider exists: `aws iam list-open-id-connect-providers`

### Error: "Access Denied" during Terraform operations

- Verify the role has AdministratorAccess policy attached
- Check: `aws iam list-attached-role-policies --role-name github-actions-smus-demo`

### Workflow doesn't trigger

- Ensure the workflow file is in `.github/workflows/deploy.yml`
- Check that you're pushing to the `main` branch
- Verify GitHub Actions are enabled in your repo settings

## Security Notes

- This setup uses AdministratorAccess for simplicity
- For production, use least-privilege policies
- The role can only be assumed by your specific GitHub repo
- No long-lived AWS credentials are stored in GitHub
