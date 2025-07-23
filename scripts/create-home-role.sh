#!/bin/bash

# Create a specific role for digstationlabs/home repository

set -e

ROLE_NAME="GitHubActions-DigstationLabsHome"
ACCOUNT_ID="529370324189"

echo "Creating IAM role specifically for digstationlabs/home..."

# Create trust policy
cat > home-trust-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:digstationlabs/home:*"
                }
            }
        }
    ]
}
EOF

# Create the role
echo "Creating role: $ROLE_NAME"
aws iam create-role \
    --role-name $ROLE_NAME \
    --assume-role-policy-document file://home-trust-policy.json \
    --description "GitHub Actions role for digstationlabs/home repository"

# Attach PowerUserAccess policy
echo "Attaching PowerUserAccess policy..."
aws iam attach-role-policy \
    --role-name $ROLE_NAME \
    --policy-arn arn:aws:iam::aws:policy/PowerUserAccess

# Create and attach CDK-specific policy
cat > cdk-iam-policy.json <<EOF
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

POLICY_NAME="GitHubActions-CDK-IAM-Policy"
echo "Creating CDK IAM policy..."
aws iam create-policy \
    --policy-name $POLICY_NAME \
    --policy-document file://cdk-iam-policy.json \
    --description "IAM permissions for CDK deployments"

aws iam attach-role-policy \
    --role-name $ROLE_NAME \
    --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/${POLICY_NAME}

# Get the role ARN
ROLE_ARN=$(aws iam get-role --role-name $ROLE_NAME --query 'Role.Arn' --output text)

# Clean up
rm -f home-trust-policy.json cdk-iam-policy.json

echo ""
echo "✅ Role created successfully!"
echo ""
echo "Role ARN: $ROLE_ARN"
echo ""
echo "Update your GitHub workflows to use this role ARN:"
echo "  $ROLE_ARN"