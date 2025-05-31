#!/bin/bash

# Default template file
TEMPLATE_FILE=${1:-"infraascode.yaml"}
DIAGRAM_FILE="infrastructure-diagram.md"

# Check if file exists
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "Error: Template file not found at $TEMPLATE_FILE"
    exit 1
fi

echo "Validating CloudFormation template: $TEMPLATE_FILE"

# Validate the template using AWS CLI
VALIDATION_RESULT=$(aws cloudformation validate-template --template-body file://$TEMPLATE_FILE 2>&1)
VALIDATION_STATUS=$?

if [ $VALIDATION_STATUS -eq 0 ]; then
    echo "✅ Template validation successful!"
    
    # Extract and display parameters
    PARAMS=$(echo "$VALIDATION_RESULT" | grep -o '"Parameters": \[[^]]*\]' | grep -o '"ParameterKey": "[^"]*"' | cut -d'"' -f4)
    
    if [ ! -z "$PARAMS" ]; then
        echo -e "\nTemplate Parameters:"
        echo "$PARAMS" | while read param; do
            echo "  - $param"
        done
    fi
    
    # Extract and display capabilities
    CAPABILITIES=$(echo "$VALIDATION_RESULT" | grep -o '"Capabilities": \[[^]]*\]' | grep -o '"[A-Z_]*"' | cut -d'"' -f2)
    
    if [ ! -z "$CAPABILITIES" ]; then
        echo -e "\nRequired Capabilities:"
        echo "$CAPABILITIES" | while read capability; do
            echo "  - $capability"
        done
    fi
    
    # Display infrastructure diagram if available
    if [ -f "$DIAGRAM_FILE" ]; then
        echo -e "\n📊 Infrastructure Diagram available at: $DIAGRAM_FILE"
        echo "   View this file in a Markdown viewer that supports Mermaid diagrams"
    else
        echo -e "\n⚠️  Infrastructure diagram not found at $DIAGRAM_FILE"
    fi
    
    exit 0
else
    echo "❌ Template validation failed!"
    echo "$VALIDATION_RESULT"
    exit 1
fi