#!/bin/bash
#================================================================================
# Script: check_env.sh
# Purpose:
#   - Validate that all required CLI tools are available in PATH
#   - Verify AWS CLI connectivity and authentication
#   - Abort early if prerequisites are not met
#================================================================================

#--------------------------------------------------------------------------------
# 0. Strict Error Handling
#--------------------------------------------------------------------------------
set -euo pipefail
IFS=$'\n\t'

#--------------------------------------------------------------------------------
# 1. Validate Required Commands
#--------------------------------------------------------------------------------
echo "NOTE: Validating that required commands are found in PATH..."

# List of required command-line tools
commands=("aws" "terraform" "jq")

# Flag to track whether all commands are present
all_found=true

# Loop through each required command and verify availability
for cmd in "${commands[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "ERROR: $cmd is not found in the current PATH."
        all_found=false
    else
        echo "NOTE: $cmd is found in the current PATH."
    fi
done

# Exit if any command was missing
if [ "$all_found" = false ]; then
    echo "ERROR: One or more required commands are missing."
    exit 1
fi

echo "NOTE: All required commands are available."

#--------------------------------------------------------------------------------
# 2. Validate AWS CLI Connectivity
#--------------------------------------------------------------------------------
echo "NOTE: Checking AWS CLI connection..."

# Attempt to retrieve AWS account identity to confirm credentials are valid
if ! aws sts get-caller-identity --query "Account" --output text &> /dev/null; then
    echo "ERROR: Failed to connect to AWS. Please check your credentials and environment."
    exit 1
fi

echo "NOTE: Successfully authenticated with AWS."

#--------------------------------------------------------------------------------
# 3. Validation Complete
#--------------------------------------------------------------------------------
echo "NOTE: Environment validation successful."
#================================================================================
