[![License: Unlicense](https://img.shields.io/badge/license-Unlicense-white.svg)](https://choosealicense.com/licenses/unlicense/) [![GitHub pull-requests closed](https://img.shields.io/github/issues-pr-closed/kunduso/aws-beanstalk-nodejs-terraform)](https://github.com/kunduso/aws-beanstalk-nodejs-terraform/pulls?q=is%3Apr+is%3Aclosed) [![GitHub pull-requests](https://img.shields.io/github/issues-pr/kunduso/aws-beanstalk-nodejs-terraform)](https://GitHub.com/kunduso/aws-beanstalk-nodejs-terraform/pull/) 
[![GitHub issues-closed](https://img.shields.io/github/issues-closed/kunduso/aws-beanstalk-nodejs-terraform)](https://github.com/kunduso/aws-beanstalk-nodejs-terraform/issues?q=is%3Aissue+is%3Aclosed) [![GitHub issues](https://img.shields.io/github/issues/kunduso/aws-beanstalk-nodejs-terraform)](https://GitHub.com/kunduso/aws-beanstalk-nodejs-terraform/issues/) 
[![terraform-infra-provisioning](https://github.com/kunduso/aws-beanstalk-nodejs-terraform/actions/workflows/terraform.yml/badge.svg)](https://github.com/kunduso/aws-beanstalk-nodejs-terraform/actions/workflows/terraform.yml) [![checkov-scan](https://github.com/kunduso/aws-beanstalk-nodejs-terraform/actions/workflows/code-scan.yml/badge.svg)](https://github.com/kunduso/aws-beanstalk-nodejs-terraform/actions/workflows/code-scan.yml)


## Introduction

This repository demonstrates how to deploy a Node.js application to AWS Elastic Beanstalk using Terraform for infrastructure as code and GitHub Actions for CI/CD automation. The project showcases modern DevOps practices including automated infrastructure provisioning, cost estimation with Infracost, and security scanning with Checkov.

The sample application is a simple to-do list built with Express.js that demonstrates basic task management operations. The infrastructure is designed with scalable features including auto-scaling, load balancing, enhanced monitoring, and secure networking with private subnets.

For a detailed walkthrough of this implementation, check out the comprehensive blog post: [Deploy Node.js Applications to AWS Elastic Beanstalk with Terraform and GitHub Actions](https://skundunotes.com/2025/12/31/deploy-node-js-applications-to-aws-elastic-beanstalk-with-terraform-and-github-actions/)

## Architecture Overview
This solution demonstrates a scalable Node.js application deployment on AWS using the following architecture.
![Architecture Diagram](https://skdevops.wordpress.com/wp-content/uploads/2025/12/124-image-1.png)

### Core Components

**Application Layer:**
- **Node.js To-Do App**: Simple Express.js application with basic HTML escaping and input sanitization
- **Elastic Beanstalk Environment**: Managed platform running Node.js 20 on Amazon Linux 2023
- **Application Load Balancer**: Distributes traffic across multiple EC2 instances
- **Auto Scaling Group**: Automatically scales between 1-3 instances based on CPU utilization

**Infrastructure Layer:**
- **VPC with Public/Private Subnets**: Secure network isolation across two availability zones
- **NAT Gateway**: Enables outbound internet access for private subnet instances
- **Security Groups**: Granular network access control for ALB and EC2 instances
- **S3 Bucket**: Stores application versions with encryption and lifecycle policies

**Monitoring & Operations:**
- **CloudWatch Logs**: Centralized logging with 7-day retention
- **Enhanced Health Reporting**: Application and infrastructure monitoring capabilities
- **Managed Platform Updates**: Automated minor version updates on Sundays

**CI/CD Pipeline:**
- **GitHub Actions**: Automated Terraform workflows with OIDC authentication
- **Infracost Integration**: Cost estimation for infrastructure changes
- **Checkov Security Scanning**: Infrastructure security validation
- **Workflow Automation**: Terraform workflows with OIDC authentication for different environments

### Security Features

- EC2 instances deployed in private subnets with no public IP addresses
- Application Load Balancer in public subnets handling external traffic
- IAM roles with least-privilege access for Beanstalk service and EC2 instances
- S3 bucket encryption and public access blocking
- Security groups restricting traffic to necessary ports only

## Prerequisites
For this code to function without errors, create an OpenID Connect identity provider in Amazon Identity and Access Management that has a trust relationship with this GitHub repository. You can read about it [here](https://skundunotes.com/2023/02/28/securely-integrate-aws-credentials-with-github-actions-using-openid-connect/) to get a detailed explanation with steps.

Store the `ARN` of the `IAM Role` as a GitHub secret which is referenced in the [`terraform.yml`](./.github/workflows/terraform.yml) file.

For Infracost integration in this repository, the `INFRACOST_API_KEY` needs to be stored as a repository secret. It is referenced in the [`terraform.yml`](./.github/workflows/terraform.yml) GitHub actions workflow file.

Additionally, the cost estimate process is managed using a GitHub Actions variable `INFRACOST_SCAN_TYPE` where the value is either `hcl_code` or `tf_plan`, depending on the type of scan desired.

You can read about that at - [integrate-Infracost-with-GitHub-Actions](https://skundunotes.com/2023/07/17/estimate-aws-cloud-resource-cost-with-infracost-terraform-and-github-actions/).

## Contributing
If you find any issues or have suggestions for improvement, feel free to open an issue or submit a pull request. Contributions are always welcome!

## License
This code is released under the Unlicense License. See [LICENSE](LICENSE).