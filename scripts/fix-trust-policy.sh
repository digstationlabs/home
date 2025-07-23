#!/bin/bash

# Fix GitHubActionsRole trust policy to include home repository
# This script updates the existing role to allow both mcp-camera and home repos

echo "Updating GitHubActionsRole trust policy..."

aws iam update-assume-role-policy \
    --role-name GitHubActionsRole \
    --policy-document file://$(dirname "$0")/update-trust-policy.json \
    --profile digstationlabs

echo "Trust policy updated successfully!"
echo "The role now allows access from:"
echo "  - repo:digstationlabs/mcp-camera:*"
echo "  - repo:digstationlabs/home:*"