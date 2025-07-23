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

# Deploy to production (requires AWS profile: digstationlabs)
npm run deploy

# Deploy to development environment
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
└── infrastructure/    # AWS CDK deployment code
    ├── bin/app.js     # CDK app entry point
    └── lib/website-stack.js  # Infrastructure definition
```

### Infrastructure

- **AWS CDK v2** for infrastructure as code
- **S3** for static file hosting (private bucket)
- **CloudFront** for global CDN distribution with security headers
- **Route53** for DNS management
- **ACM** for SSL certificates (must be in us-east-1)

### Deployment Architecture

1. Content is stored in a private S3 bucket
2. CloudFront serves content with Origin Access Identity (OAI)
3. Security headers are applied via Response Headers Policy
4. Automatic cache invalidation on deployment
5. Separate environments: dev and prod

### Key Features

- Hot-reload development server using `live-server`
- Multipage static site with shared navigation
- Mobile-responsive design
- Security headers (HSTS, CSP, X-Frame-Options, etc.)
- HTTP/2 and HTTP/3 support
- IPv6 enabled

## Notes

- AWS profile must be configured as `digstationlabs`
- SSL certificates must be created in us-east-1 region
- Domain configuration in `infrastructure/cdk.json`
- GitHub Actions workflow requires AWS OIDC role setup
- No build step required - plain HTML/CSS/JS