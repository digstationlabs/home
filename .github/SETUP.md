# GitHub Actions Setup for Digstation Labs

This document explains how to set up GitHub Actions for automated deployment to AWS.

## Prerequisites

1. AWS Account with appropriate permissions
2. GitHub repository for the project
3. AWS CDK bootstrapped in your AWS account

## Step 1: Create OIDC Identity Provider in AWS

1. Go to AWS IAM Console
2. Navigate to Identity providers
3. Click "Add provider"
4. Choose "OpenID Connect"
5. Provider URL: `https://token.actions.githubusercontent.com`
6. Audience: `sts.amazonaws.com`

## Step 2: Create IAM Role for GitHub Actions

Create a new IAM role with the following trust policy:

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
          "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_ORG/digstationlabs-home:*"
        }
      }
    }
  ]
}
```

## Step 3: Attach Permissions to the Role

The role needs the following permissions:
- CloudFormation full access (for CDK deployments)
- S3 access (for bucket creation and content upload)
- CloudFront access (for distribution management)
- Route53 access (for DNS management)
- IAM access (for creating service roles)
- ACM read access (for certificate validation)

You can use the AWS managed policy `PowerUserAccess` or create a custom policy.

## Step 4: Configure GitHub Secrets

In your GitHub repository settings, add the following secret:

- `AWS_DEPLOY_ROLE_ARN`: The ARN of the IAM role created in step 2

## Step 5: Configure GitHub Environments

Create two environments in your repository settings:

1. **dev**
   - No protection rules required
   - URL: https://dev.digstationlabs.com

2. **prod**
   - Add protection rules:
     - Required reviewers (optional)
     - Restrict deployments to main branch
   - URL: https://digstationlabs.com

## Usage

### Manual Deployment

1. Go to Actions tab in GitHub
2. Select "Manual Deploy" workflow
3. Click "Run workflow"
4. Choose environment (dev or prod)
5. Type "deploy" to confirm
6. Click "Run workflow"

### Automatic Deployment

- Push to `main` branch automatically deploys to dev environment
- After successful dev deployment, it deploys to prod (with environment protection if configured)

## Troubleshooting

### CDK Bootstrap Required

If you see an error about CDK bootstrap, run:

```bash
cd infrastructure
npx cdk bootstrap aws://ACCOUNT_ID/us-east-1 --profile digstationlabs
```

### Permission Errors

Ensure the IAM role has sufficient permissions for:
- Creating/updating CloudFormation stacks
- Creating/modifying S3 buckets
- Creating/modifying CloudFront distributions
- Creating/modifying Route53 records

### Certificate Issues

- Ensure SSL certificate exists in us-east-1 region
- Certificate must be validated
- Certificate must cover both root domain and www subdomain