# AWS CloudFormation Infrastructure as Code

This repository contains CloudFormation templates and utility scripts for deploying a highly available web application infrastructure on AWS.

## Architecture

The infrastructure includes:

- VPC with public and private subnets across multiple availability zones
- Internet Gateway and route tables
- Application Load Balancer
- Security groups for web and database tiers
- RDS MySQL database in private subnets

See the [infrastructure diagram](infrastructure-diagram.md) for a visual representation.

## Files

- `infraascode.yaml` - Main CloudFormation template
- `infrastructure-diagram.md` - Visual diagram of the infrastructure
- `validate_template.sh` - Script to validate CloudFormation templates
- `validate_template.py` - Python version of the validation script
- `validate_template.bat` - Windows batch version of the validation script
- `deploy_stack.sh` - Script to create or update CloudFormation stacks
- `params-example.json` - Example parameters file for CloudFormation deployment

## Prerequisites

- AWS CLI installed and configured
- AWS account with appropriate permissions
- Bash shell (for .sh scripts) or Windows command prompt (for .bat scripts)
- Python (for Python scripts)

## Usage

### Validating Templates

```bash
# Using bash script
./validate_template.sh [template-file]

# Using Python script
python validate_template.py [template-file]

# Using batch file (Windows)
validate_template.bat [template-file]
```

### Deploying Stacks

```bash
# Create a new stack
./deploy_stack.sh --stack my-stack-name --action create --params params-example.json

# Update an existing stack
./deploy_stack.sh --stack my-stack-name --action update --params params-example.json
```

### Parameters

Before deployment, update the `params-example.json` file with your actual parameter values:

```json
[
  {
    "ParameterKey": "DBPassword",
    "ParameterValue": "YourSecurePasswordHere"
  }
]
```

## Security Notes

- The template includes security groups with some open access (0.0.0.0/0) for demonstration purposes
- For production use, restrict access to specific IP ranges
- Store sensitive parameters like database passwords securely
- Consider using AWS Secrets Manager for credential management

## Viewing the Infrastructure Diagram

The infrastructure diagram is created using Mermaid syntax and can be viewed in:
- GitHub (which supports Mermaid diagrams)
- VS Code with the Mermaid extension
- Any Markdown viewer that supports Mermaid syntax