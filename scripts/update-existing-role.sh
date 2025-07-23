#!/bin/bash

# Update existing GitHubActionsRole to allow home repository

set -e

echo "Updating GitHubActionsRole trust policy to include home repository..."

# Create updated trust policy
cat > trust-policy-update.json <<'EOF'
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
                        "repo:digstationlabs/mcp-camera:*",
                        "repo:digstationlabs/home:*"
                    ]
                }
            }
        }
    ]
}
EOF

# Update the role's trust policy
aws iam update-assume-role-policy \
    --role-name GitHubActionsRole \
    --policy-document file://trust-policy-update.json

# Clean up
rm -f trust-policy-update.json

echo "✅ Trust policy updated successfully!"
echo ""
echo "The GitHubActionsRole can now be used by both repositories:"
echo "- digstationlabs/mcp-camera"
echo "- digstationlabs/home"