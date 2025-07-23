#!/usr/bin/env node

const cdk = require('aws-cdk-lib');
const { WebsiteStack } = require('../lib/website-stack');

const app = new cdk.App();

const environment = app.node.tryGetContext('environment') || 'dev';
const envConfig = app.node.tryGetContext('environments')[environment];

if (!envConfig) {
    throw new Error(`Configuration for environment "${environment}" not found`);
}

new WebsiteStack(app, `DigstationLabsHome-${environment}`, {
    env: {
        account: process.env.CDK_DEFAULT_ACCOUNT,
        region: 'us-east-1', // CloudFront certificates must be in us-east-1
    },
    environment,
    ...envConfig,
    description: `Digstation Labs home page infrastructure - ${environment}`,
});