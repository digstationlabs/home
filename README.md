# Digstation Labs Home Page

Static website for Digstation Labs built with plain HTML, CSS, and JavaScript.

## Quick Start

```bash
# Install dependencies
npm install

# Start development server
npm start
```

Visit http://localhost:8080 to view the site.

## Deployment

### Local Deployment (requires AWS CLI)

```bash
# Install infrastructure dependencies
npm run install-infra

# Deploy to dev environment
npm run deploy-dev

# Deploy to production
npm run deploy
```

Requires AWS credentials configured with the `digstationlabs` profile.

### GitHub Actions Deployment

The project includes automated deployment workflows:

1. **Manual Deployment**: Use the "Manual Deploy" workflow in GitHub Actions
2. **Automatic Deployment**: Push to `main` branch triggers deployment to dev, then prod

See [.github/SETUP.md](.github/SETUP.md) for GitHub Actions configuration instructions.