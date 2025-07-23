# Deployment Status - Digstation Labs Home

## Current Status: AWS OIDC Authentication Issue

### Problem
GitHub Actions deployment is failing with:
```
Error: Could not assume role with OIDC: Not authorized to perform sts:AssumeRoleWithWebIdentity
```

### Root Cause
The `GitHubActionsRole` (arn:aws:iam::529370324189:role/GitHubActionsRole) currently only trusts the `mcp-camera` repository, not the `home` repository.

### Solution Required
Run one of these scripts with AWS CLI configured:

1. **Update existing role** (recommended):
   ```bash
   bash scripts/check-and-fix-role.sh
   ```

2. **Create new role** (alternative):
   ```bash
   bash scripts/create-home-role.sh
   ```

### What's Been Done
✅ Project structure created (HTML, CSS, JS files)
✅ AWS CDK infrastructure code written
✅ GitHub Actions workflows created
✅ All code pushed to GitHub
✅ Scripts created to fix the IAM role trust policy
❌ IAM role trust policy needs to be updated (pending)

### Next Steps
1. Run the check-and-fix-role.sh script to update the IAM role
2. The GitHub Actions workflow should then work automatically
3. Site will deploy to CloudFront/S3

### Project Details
- **Domain**: digstationlabs.com
- **Certificate ARN**: arn:aws:acm:us-east-1:529370324189:certificate/36622163-572c-4c43-a4b3-05dbafc7fc7e
- **AWS Account**: 529370324189
- **GitHub Repo**: digstationlabs/home
- **Deployment Method**: AWS CDK via GitHub Actions OIDC

### Files to Check
- `.github/workflows/deploy-on-push.yml` - Main deployment workflow
- `.github/workflows/test-aws-connection.yml` - Use this to test if auth is working
- `scripts/check-and-fix-role.sh` - Script to fix the IAM role
- `infrastructure/` - CDK code for AWS deployment