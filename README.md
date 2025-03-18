# AWS Infrastructure Repository

This repository contains infrastructure as code (IaC) for AWS resources using both CloudFormation and Terraform.

## Repository Structure

```
infrastructure/
├── cloudformation/  # CloudFormation templates
├── terraform/       # Terraform configurations
│   ├── s3-example/  # S3 bucket example
│   └── ec2-ollama/  # EC2 with Ollama in Frankfurt
└── iam-policies/    # IAM policies for required permissions
```

## Prerequisites

- AWS CLI installed and configured
- Terraform installed (for Terraform deployments)
- Appropriate IAM permissions (see the iam-policies directory)

## AWS CLI Configuration

To configure AWS CLI with your credentials:

```bash
aws configure
```

You will be prompted to enter:
- AWS Access Key ID
- AWS Secret Access Key
- Default region
- Default output format

## Required IAM Permissions

Before you can use CloudFormation or Terraform to manage AWS resources, you need the appropriate permissions. Check the `infrastructure/iam-policies` directory for policy templates and instructions on how to apply them.

If you encounter permission errors like:
```
An error occurred (AccessDenied) when calling the ValidateTemplate operation: User: arn:aws:iam::YOUR_ACCOUNT_ID:user/YOUR_USERNAME is not authorized to perform: cloudformation:ValidateTemplate
```

You need to apply the appropriate IAM policy to your user.

## CloudFormation Usage

To deploy a CloudFormation stack:

```bash
aws cloudformation deploy --template-file <template-file> --stack-name <stack-name> --parameter-overrides <parameters>
```

To validate a CloudFormation template:

```bash
aws cloudformation validate-template --template-body file://<template-file>
```

## Terraform Usage

To initialize a Terraform configuration:

```bash
cd infrastructure/terraform/<project>
terraform init
terraform plan
terraform apply
```

## EC2 with Ollama in Frankfurt

This repository includes a Terraform configuration to deploy an EC2 instance in the Frankfurt (eu-central-1) region with Ollama pre-installed:

```bash
cd infrastructure/terraform/ec2-ollama
terraform init
terraform apply -var="environment=dev" -var="ssh_public_key_path=~/.ssh/id_rsa.pub"
```

See the [EC2 Ollama README](infrastructure/terraform/ec2-ollama/README.md) for more details.

## CI/CD Setup

This repository includes GitHub Actions workflows for CI/CD:

- Feature branches deploy to the dev environment
- The main branch deploys to the prod environment
- Pull requests run validation but don't deploy resources

See the workflow configuration in `.github/workflows/terraform.yml`.

## Best Practices

1. Use version control for all infrastructure code
2. Use parameters and variables for reusable templates
3. Implement proper tagging strategy
4. Use separate stacks/modules for different environments
5. Document all resources and their dependencies
6. Apply the principle of least privilege for IAM permissions 