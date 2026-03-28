#!/bin/bash

# Setup GitHub OIDC for Terraform Deployment
# Usage: ./setup-github-oidc.sh YOUR_GITHUB_USERNAME YOUR_REPO_NAME

set -e

if [ $# -ne 2 ]; then
    echo "Usage: $0 <github-username> <repo-name>"
    echo "Example: $0 nobelx smus-networking-demo"
    exit 1
fi

GITHUB_USERNAME=$1
REPO_NAME=$2
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="us-east-1"

echo "=========================================="
echo "GitHub OIDC Setup for Terraform"
echo "=========================================="
echo "GitHub Repo: ${GITHUB_USERNAME}/${REPO_NAME}"
echo "AWS Account: ${AWS_ACCOUNT_ID}"
echo "Region: ${REGION}"
echo "=========================================="

# Step 1: Create OIDC Provider (if not exists)
echo ""
echo "Step 1: Creating OIDC Provider..."
aws iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --client-id-list sts.amazonaws.com \
    --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
    2>/dev/null && echo "✓ OIDC Provider created" || echo "✓ OIDC Provider already exists"

# Step 2: Create Trust Policy
echo ""
echo "Step 2: Creating IAM Role Trust Policy..."
cat > /tmp/trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:${GITHUB_USERNAME}/${REPO_NAME}:*"
        }
      }
    }
  ]
}
EOF

# Step 3: Create IAM Role
echo ""
echo "Step 3: Creating IAM Role..."
ROLE_NAME="github-actions-smus-demo"
aws iam create-role \
    --role-name ${ROLE_NAME} \
    --assume-role-policy-document file:///tmp/trust-policy.json \
    --description "Role for GitHub Actions to deploy SMUS demo" \
    2>/dev/null && echo "✓ IAM Role created" || echo "✓ IAM Role already exists"

# Step 4: Attach Policies
echo ""
echo "Step 4: Attaching IAM Policies..."
aws iam attach-role-policy \
    --role-name ${ROLE_NAME} \
    --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

echo "✓ AdministratorAccess policy attached"

# Step 5: Get Role ARN
ROLE_ARN=$(aws iam get-role --role-name ${ROLE_NAME} --query Role.Arn --output text)

# Cleanup
rm /tmp/trust-policy.json

echo ""
echo "=========================================="
echo "✓ Setup Complete!"
echo "=========================================="
echo ""
echo "Next Steps:"
echo ""
echo "1. Add these secrets to your GitHub repository:"
echo "   Go to: https://github.com/${GITHUB_USERNAME}/${REPO_NAME}/settings/secrets/actions"
echo ""
echo "   Add the following secrets:"
echo "   • Name: AWS_ROLE_ARN"
echo "     Value: ${ROLE_ARN}"
echo ""
echo "   • Name: AWS_REGION"
echo "     Value: ${REGION}"
echo ""
echo "2. Push your code to trigger GitHub Actions:"
echo "   git push origin main"
echo ""
echo "=========================================="
