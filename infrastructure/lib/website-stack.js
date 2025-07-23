const { Stack, Duration, RemovalPolicy, CfnOutput } = require('aws-cdk-lib');
const s3 = require('aws-cdk-lib/aws-s3');
const cloudfront = require('aws-cdk-lib/aws-cloudfront');
const cloudfront_origins = require('aws-cdk-lib/aws-cloudfront-origins');
const s3deploy = require('aws-cdk-lib/aws-s3-deployment');
const certificatemanager = require('aws-cdk-lib/aws-certificatemanager');
const route53 = require('aws-cdk-lib/aws-route53');
const route53_targets = require('aws-cdk-lib/aws-route53-targets');
const path = require('path');

class WebsiteStack extends Stack {
    constructor(scope, id, props) {
        super(scope, id, props);

        const { environment, domainName, certificateArn, hostedZoneId, hostedZoneName } = props;

        // Create S3 bucket for website content
        const contentBucket = new s3.Bucket(this, 'ContentBucket', {
            bucketName: `digstationlabs-home-${environment}-content`,
            versioned: true,
            removalPolicy: RemovalPolicy.RETAIN,
            encryption: s3.BucketEncryption.S3_MANAGED,
            blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
        });

        // Create S3 bucket for CloudFront logs
        const logsBucket = new s3.Bucket(this, 'LogsBucket', {
            bucketName: `digstationlabs-home-${environment}-logs`,
            removalPolicy: RemovalPolicy.RETAIN,
            encryption: s3.BucketEncryption.S3_MANAGED,
            objectOwnership: s3.ObjectOwnership.BUCKET_OWNER_PREFERRED,
            blockPublicAccess: new s3.BlockPublicAccess({
                blockPublicAcls: false,
                blockPublicPolicy: true,
                ignorePublicAcls: false,
                restrictPublicBuckets: true,
            }),
            lifecycleRules: [{
                expiration: Duration.days(90),
            }],
        });

        // Create Origin Access Identity for CloudFront
        const originAccessIdentity = new cloudfront.OriginAccessIdentity(this, 'OAI', {
            comment: `OAI for Digstation Labs ${environment}`,
        });

        // Grant read permissions to CloudFront
        contentBucket.grantRead(originAccessIdentity);

        // Get certificate (must exist in us-east-1)
        const certificate = certificateArn !== 'PENDING_CERTIFICATE_ARN' 
            ? certificatemanager.Certificate.fromCertificateArn(this, 'Certificate', certificateArn)
            : undefined;

        // Security headers policy
        const responseHeadersPolicy = new cloudfront.ResponseHeadersPolicy(this, 'SecurityHeadersPolicy', {
            responseHeadersPolicyName: `DigstationLabs-${environment}-SecurityHeaders`,
            securityHeadersBehavior: {
                contentTypeOptions: { override: true },
                frameOptions: { frameOption: cloudfront.HeadersFrameOption.DENY, override: true },
                referrerPolicy: { 
                    referrerPolicy: cloudfront.HeadersReferrerPolicy.STRICT_ORIGIN_WHEN_CROSS_ORIGIN, 
                    override: true 
                },
                strictTransportSecurity: {
                    accessControlMaxAge: Duration.seconds(63072000),
                    includeSubdomains: true,
                    override: true,
                },
                xssProtection: { protection: true, modeBlock: true, override: true },
            },
        });

        // Create CloudFront distribution
        const distribution = new cloudfront.Distribution(this, 'Distribution', {
            defaultRootObject: 'index.html',
            domainNames: certificate && domainName ? [domainName, `www.${domainName}`] : undefined,
            certificate,
            minimumProtocolVersion: cloudfront.SecurityPolicyProtocol.TLS_V1_2_2021,
            defaultBehavior: {
                origin: new cloudfront_origins.S3Origin(contentBucket, {
                    originAccessIdentity,
                }),
                compress: true,
                viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
                responseHeadersPolicy,
                cachePolicy: cloudfront.CachePolicy.CACHING_OPTIMIZED,
            },
            errorResponses: [
                {
                    httpStatus: 404,
                    responseHttpStatus: 404,
                    responsePagePath: '/404.html',
                    ttl: Duration.minutes(5),
                },
            ],
            logBucket: logsBucket,
            logFilePrefix: 'cloudfront-logs/',
            priceClass: cloudfront.PriceClass.PRICE_CLASS_100,
            httpVersion: cloudfront.HttpVersion.HTTP2_AND_3,
            ipv6: true,
        });

        // Deploy website content
        new s3deploy.BucketDeployment(this, 'DeployWebsite', {
            sources: [s3deploy.Source.asset(path.join(__dirname, '../../'), {
                exclude: [
                    'node_modules',
                    'node_modules/**',
                    '**/node_modules/**',
                    'infrastructure',
                    'infrastructure/**',
                    '.git',
                    '.git/**',
                    '.github',
                    '.github/**',
                    '*.log',
                    '.DS_Store',
                    'package.json',
                    'package-lock.json',
                    'CLAUDE.md',
                    '.gitignore',
                    'scripts',
                    'scripts/**',
                ],
            })],
            destinationBucket: contentBucket,
            distribution,
            distributionPaths: ['/*'],
        });

        // Create Route53 records if domain is configured
        if (domainName && hostedZoneId && hostedZoneId !== 'PENDING_ZONE_ID' && certificate) {
            const zone = route53.HostedZone.fromHostedZoneAttributes(this, 'Zone', {
                zoneName: hostedZoneName || domainName,
                hostedZoneId: hostedZoneId,
            });

            // Create A record for root domain
            new route53.ARecord(this, 'ARecord', {
                recordName: domainName,
                target: route53.RecordTarget.fromAlias(
                    new route53_targets.CloudFrontTarget(distribution)
                ),
                zone,
            });

            // Create A record for www subdomain
            new route53.ARecord(this, 'WWWARecord', {
                recordName: `www.${domainName}`,
                target: route53.RecordTarget.fromAlias(
                    new route53_targets.CloudFrontTarget(distribution)
                ),
                zone,
            });
        }

        // Output values
        new CfnOutput(this, 'DistributionId', {
            value: distribution.distributionId,
            description: 'CloudFront Distribution ID',
        });

        new CfnOutput(this, 'DistributionDomainName', {
            value: distribution.distributionDomainName,
            description: 'CloudFront Distribution Domain Name',
        });

        new CfnOutput(this, 'ContentBucketName', {
            value: contentBucket.bucketName,
            description: 'S3 Content Bucket Name',
        });

        if (domainName && certificate) {
            new CfnOutput(this, 'WebsiteURL', {
                value: `https://${domainName}`,
                description: 'Website URL',
            });
        }
    }
}

module.exports = { WebsiteStack };