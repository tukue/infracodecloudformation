#!/bin/bash

# Default values
TEMPLATE_FILE="infraascode.yaml"
STACK_NAME=""
ACTION=""
PARAMS_FILE=""

# Function to display usage
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -t, --template TEMPLATE_FILE   CloudFormation template file (default: infraascode.yaml)"
    echo "  -s, --stack STACK_NAME         CloudFormation stack name (required)"
    echo "  -a, --action ACTION            Action to perform: create or update (required)"
    echo "  -p, --params PARAMS_FILE       Parameters file in JSON format (optional)"
    echo "  -h, --help                     Display this help message"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -t|--template)
            TEMPLATE_FILE="$2"
            shift 2
            ;;
        -s|--stack)
            STACK_NAME="$2"
            shift 2
            ;;
        -a|--action)
            ACTION="$2"
            shift 2
            ;;
        -p|--params)
            PARAMS_FILE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate required parameters
if [ -z "$STACK_NAME" ]; then
    echo "Error: Stack name is required"
    usage
fi

if [ -z "$ACTION" ] || ([ "$ACTION" != "create" ] && [ "$ACTION" != "update" ]); then
    echo "Error: Action must be either 'create' or 'update'"
    usage
fi

# Check if template file exists
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "Error: Template file not found at $TEMPLATE_FILE"
    exit 1
fi

# Validate template first
echo "Validating template: $TEMPLATE_FILE"
aws cloudformation validate-template --template-body file://$TEMPLATE_FILE > /dev/null

if [ $? -ne 0 ]; then
    echo "❌ Template validation failed. Please fix the errors before deploying."
    exit 1
fi

echo "✅ Template validation successful!"

# Prepare parameters
PARAMS_OPTION=""
if [ -n "$PARAMS_FILE" ]; then
    if [ ! -f "$PARAMS_FILE" ]; then
        echo "Error: Parameters file not found at $PARAMS_FILE"
        exit 1
    fi
    PARAMS_OPTION="--parameters file://$PARAMS_FILE"
fi

# Deploy stack based on action
if [ "$ACTION" == "create" ]; then
    echo "Creating new stack: $STACK_NAME"
    aws cloudformation create-stack \
        --stack-name $STACK_NAME \
        --template-body file://$TEMPLATE_FILE \
        $PARAMS_OPTION \
        --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
        --on-failure DO_NOTHING
    
    echo "Waiting for stack creation to complete..."
    aws cloudformation wait stack-create-complete --stack-name $STACK_NAME
    
    if [ $? -eq 0 ]; then
        echo "✅ Stack creation completed successfully!"
    else
        echo "❌ Stack creation failed or timed out. Check AWS Console for details."
        exit 1
    fi
    
elif [ "$ACTION" == "update" ]; then
    echo "Updating existing stack: $STACK_NAME"
    
    # Check if stack exists
    aws cloudformation describe-stacks --stack-name $STACK_NAME > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Error: Stack $STACK_NAME does not exist. Use 'create' action instead."
        exit 1
    fi
    
    aws cloudformation update-stack \
        --stack-name $STACK_NAME \
        --template-body file://$TEMPLATE_FILE \
        $PARAMS_OPTION \
        --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM
    
    echo "Waiting for stack update to complete..."
    aws cloudformation wait stack-update-complete --stack-name $STACK_NAME
    
    if [ $? -eq 0 ]; then
        echo "✅ Stack update completed successfully!"
    else
        echo "❌ Stack update failed or timed out. Check AWS Console for details."
        exit 1
    fi
fi

# Display stack outputs
echo -e "\nStack Outputs:"
aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].Outputs" --output table

echo -e "\n📊 Infrastructure Diagram available at: infrastructure-diagram.md"