# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the home page for Digstation Labs - a multipage static website built with plain HTML, CSS, and JavaScript (no frameworks). The site is deployed to AWS using CloudFront, S3, and Route53.

## Development Commands

```bash
# Install dependencies
npm install

# Start local development server with hot-reload (port 8080)
npm run dev
# or
npm start

# Install infrastructure dependencies
npm run install-infra

# Deploy to production locally (requires AWS profile: digstationlabs)
npm run deploy

# Deploy to development environment locally
npm run deploy-dev
```

## Code Architecture

### Directory Structure
```
/
├── index.html          # Home page
├── about.html          # About page
├── services.html       # Services page
├── contact.html        # Contact page
├── 404.html           # Error page
├── css/
│   └── main.css       # Main stylesheet
├── js/
│   └── main.js        # Main JavaScript file
├── images/            # Image assets
├── scripts/           # Utility scripts (OIDC setup, etc.)
├── .github/
│   └── workflows/
│       ├── deploy-on-push.yml    # Auto-deploy on push to main
│       ├── deploy-manual.yml     # Manual deployment workflow
│       └── test-aws-connection.yml # Test AWS OIDC connection
└── infrastructure/    # AWS CDK deployment code
    ├── bin/app.js     # CDK app entry point
    ├── lib/website-stack.js  # Infrastructure definition
    └── cdk.json       # CDK configuration with environments
```

### Infrastructure

- **AWS CDK v2** for infrastructure as code
- **S3** for static file hosting (private bucket with versioning)
- **CloudFront** for global CDN distribution with security headers
- **Route53** for DNS management
- **ACM** for SSL certificates (must be in us-east-1)
- **GitHub Actions** for CI/CD deployment

### Deployment Architecture

1. **Local Development**
   - `live-server` provides hot-reload development environment
   - Runs on http://localhost:8080

2. **GitHub Actions Deployment**
   - Triggered automatically on push to `main` branch
   - Uses AWS OIDC (OpenID Connect) for secure authentication
   - No long-lived AWS credentials stored in GitHub
   - Deploys to production environment only (dev disabled for now)

3. **AWS Infrastructure**
   - **S3 Buckets**: 
     - Content bucket: `digstationlabs-home-prod-content` (private, versioned)
     - Logs bucket: `digstationlabs-home-prod-logs` (lifecycle: 90 days)
   - **CloudFront Distribution**: 
     - Custom domain: https://digstationlabs.com and https://www.digstationlabs.com
     - Origin Access Identity (OAI) for secure S3 access
     - Security headers via Response Headers Policy
     - Automatic cache invalidation on deployment
   - **Route53**: 
     - Hosted Zone ID: `Z03386492TQG4M6HUKQKL`
     - A records for apex and www subdomain

### GitHub Actions Workflow

The deployment process is fully automated:

1. **Trigger**: Push to `main` branch (ignores .md files and .github/)
2. **Authentication**: Uses `GitHubActionsRole` with OIDC trust policy
3. **Steps**:
   - Checkout code
   - Setup Node.js 20.x with npm cache
   - Install dependencies
   - Configure AWS credentials via OIDC
   - Deploy using CDK with `--require-approval never`
   - Invalidate CloudFront cache

### Security Configuration

- **CloudFront Security Headers**:
  - Strict-Transport-Security (HSTS): 2 years, includeSubDomains
  - X-Frame-Options: DENY
  - X-Content-Type-Options: nosniff
  - X-XSS-Protection: 1; mode=block
  - Referrer-Policy: strict-origin-when-cross-origin

- **AWS IAM**:
  - GitHubActionsRole with trust policy for `repo:digstationlabs/home:*`
  - Minimal permissions following least privilege principle

### Key Features

- Hot-reload development server using `live-server`
- Multipage static site with shared navigation
- Mobile-responsive design
- Security headers enforced at CDN level
- HTTP/2 and HTTP/3 support
- IPv6 enabled
- Automatic deployments on git push
- Zero-downtime deployments with CloudFront

## Important Notes

- **AWS Profile**: Must use `digstationlabs` profile for local operations
- **SSL Certificates**: Must be created in us-east-1 region for CloudFront
- **Domain Configuration**: Set in `infrastructure/cdk.json`
- **OIDC Role**: `GitHubActionsRole` must trust both `mcp-camera` and `home` repos
- **No Build Step**: Plain HTML/CSS/JS - no bundling or transpilation needed
- **Deployment**: Always deploy through GitHub Actions (push to main branch)

## Troubleshooting

### Common Issues

1. **OIDC Authentication Fails**
   - Check trust policy includes `repo:digstationlabs/home:*`
   - Run: `scripts/fix-trust-policy.sh`

2. **CloudFormation Stack Fails**
   - Check for existing S3 buckets from failed deployments
   - Delete failed stack: `aws cloudformation delete-stack --stack-name DigstationLabsHome-prod --profile digstationlabs`
   - Delete orphaned buckets if needed

3. **Domain Not Accessible**
   - Verify Route53 hosted zone ID in `cdk.json`
   - Check DNS propagation (can take up to 48 hours)
   - Clear browser cache and DNS cache

## Environment Configuration

### Production (Active)
- Domain: digstationlabs.com
- Certificate ARN: arn:aws:acm:us-east-1:529370324189:certificate/36622163-572c-4c43-a4b3-05dbafc7fc7e
- Hosted Zone ID: Z03386492TQG4M6HUKQKL

### Development (Disabled)
- Currently not deployed to avoid certificate issues
- Can be enabled once dev.digstationlabs.com certificate is configured