# AWS Setup Scripts

This directory contains scripts to set up AWS IAM roles for GitHub Actions OIDC authentication.

## Problem

The `GitHubActionsRole` currently only trusts the `mcp-camera` repository, not the `home` repository.

## Solutions

### Option 1: Update Existing Role (Recommended)

Update the existing `GitHubActionsRole` to trust multiple repositories:

```bash
bash check-and-fix-role.sh
```

This will update the role to trust all repositories in the `digstationlabs` organization.

### Option 2: Create a New Role

Create a separate role specifically for the home repository:

```bash
bash create-home-role.sh
```

Then update the GitHub workflows to use the new role ARN that the script outputs.

### Option 3: Manual Fix

If you prefer to do it manually in the AWS Console:

1. Go to IAM → Roles → GitHubActionsRole
2. Click on "Trust relationships" tab
3. Click "Edit trust policy"
4. Update the condition to include both repositories:

```json
"StringLike": {
    "token.actions.githubusercontent.com:sub": [
        "repo:digstationlabs/mcp-camera:*",
        "repo:digstationlabs/home:*"
    ]
}
```

5. Click "Update policy"

## Verification

After updating, run the "Test AWS Connection" workflow in GitHub Actions to verify the fix worked.