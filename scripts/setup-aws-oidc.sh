#!/bin/bash

# Setup script for AWS OIDC with GitHub Actions
# Run this script with AWS CLI configured with appropriate permissions

set -e

echo "Setting up AWS OIDC for GitHub Actions..."

# Variables
GITHUB_ORG="digstationlabs"
GITHUB_REPO="home"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo "Error: Could not retrieve AWS account ID. Make sure AWS CLI is configured."
    exit 1
fi

echo "AWS Account ID: $AWS_ACCOUNT_ID"
echo "GitHub Repository: $GITHUB_ORG/$GITHUB_REPO"

# Create OIDC provider if it doesn't exist
EXISTING_PROVIDER=$(aws iam list-open-id-connect-providers --query "OpenIDConnectProviderList[?ends_with(Arn, 'token.actions.githubusercontent.com')].Arn" --output text)

if [ -z "$EXISTING_PROVIDER" ]; then
    echo "Creating OIDC provider..."
    THUMBPRINT="6938fd4d98bab03faadb97b34396831e3780aea1"
    aws iam create-open-id-connect-provider \
        --url https://token.actions.githubusercontent.com \
        --client-id-list sts.amazonaws.com \
        --thumbprint-list $THUMBPRINT
    echo "OIDC provider created."
else
    echo "OIDC provider already exists: $EXISTING_PROVIDER"
fi

# Create IAM role trust policy
cat > trust-policy.json <<EOF
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
                    "token.actions.githubusercontent.com:sub": "repo:${GITHUB_ORG}/${GITHUB_REPO}:*"
                }
            }
        }
    ]
}
EOF

# Create IAM role
ROLE_NAME="GitHubActions-DigstationLabsHome"
echo "Creating IAM role: $ROLE_NAME"

# Check if role exists
if aws iam get-role --role-name $ROLE_NAME 2>/dev/null; then
    echo "Role already exists. Updating trust policy..."
    aws iam update-assume-role-policy --role-name $ROLE_NAME --policy-document file://trust-policy.json
else
    echo "Creating new role..."
    aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document file://trust-policy.json
fi

# Attach necessary policies
echo "Attaching policies to role..."

# PowerUserAccess for CDK deployments
aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/PowerUserAccess

# Additional policy for CDK bootstrap
cat > cdk-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iam:CreateRole",
                "iam:AttachRolePolicy",
                "iam:PutRolePolicy",
                "iam:DeleteRole",
                "iam:DetachRolePolicy",
                "iam:DeleteRolePolicy",
                "iam:GetRole",
                "iam:GetRolePolicy",
                "iam:ListRolePolicies",
                "iam:ListAttachedRolePolicies",
                "iam:UpdateAssumeRolePolicy",
                "iam:PassRole"
            ],
            "Resource": "*"
        }
    ]
}
EOF

POLICY_NAME="GitHubActions-CDK-Policy"
POLICY_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME}"

# Check if policy exists
if aws iam get-policy --policy-arn $POLICY_ARN 2>/dev/null; then
    echo "Policy already exists."
else
    echo "Creating CDK policy..."
    aws iam create-policy --policy-name $POLICY_NAME --policy-document file://cdk-policy.json
fi

aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn $POLICY_ARN

# Get role ARN
ROLE_ARN=$(aws iam get-role --role-name $ROLE_NAME --query Role.Arn --output text)

# Clean up temporary files
rm -f trust-policy.json cdk-policy.json

echo ""
echo "✅ Setup complete!"
echo ""
echo "Add this secret to your GitHub repository:"
echo "  Name: AWS_DEPLOY_ROLE_ARN"
echo "  Value: $ROLE_ARN"
echo ""
echo "To add the secret:"
echo "1. Go to https://github.com/$GITHUB_ORG/$GITHUB_REPO/settings/secrets/actions"
echo "2. Click 'New repository secret'"
echo "3. Add the secret with the name and value above"
echo ""
echo "Also ensure you have created the GitHub environments:"
echo "- dev"
echo "- prod"