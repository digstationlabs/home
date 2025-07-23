#!/bin/bash

# Check and fix GitHubActionsRole trust policy

set -e

echo "Checking current trust policy for GitHubActionsRole..."

# Get current trust policy
aws iam get-role --role-name GitHubActionsRole --query 'Role.AssumeRolePolicyDocument' > current-trust-policy.json

echo "Current trust policy:"
cat current-trust-policy.json | jq .

# Create the correct trust policy
cat > new-trust-policy.json <<'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::529370324189:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": [
                        "repo:digstationlabs/*:*"
                    ]
                }
            }
        }
    ]
}
EOF

echo ""
echo "Updating trust policy to allow all digstationlabs repositories..."

# Update the role's trust policy
aws iam update-assume-role-policy \
    --role-name GitHubActionsRole \
    --policy-document file://new-trust-policy.json

# Verify the update
echo ""
echo "Verifying updated trust policy..."
aws iam get-role --role-name GitHubActionsRole --query 'Role.AssumeRolePolicyDocument' | jq .

# Clean up
rm -f current-trust-policy.json new-trust-policy.json

echo ""
echo "✅ Trust policy updated successfully!"
echo ""
echo "The GitHubActionsRole can now be used by ALL repositories in the digstationlabs organization."
echo ""
echo "Alternatively, if you prefer to limit to specific repos, use this pattern:"
echo '  "token.actions.githubusercontent.com:sub": ['
echo '      "repo:digstationlabs/mcp-camera:*",'
echo '      "repo:digstationlabs/home:*"'
echo '  ]'