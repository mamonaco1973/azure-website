#!/bin/bash

# ============================================================================================
# Script: check_env.sh
# Purpose:
#   - Validate that required commands and environment variables exist
#   - Confirm Azure CLI login using a Service Principal
# ============================================================================================

# ============================================================================================
# STEP 0: VALIDATE REQUIRED COMMANDS
# ============================================================================================

echo "NOTE: Validating that required commands are found in your PATH."

# Define required CLI tools
commands=("az" "terraform" "jq")

# Flag to track validation status
all_found=true

# --------------------------------------------------------------------------------------------
# Iterate through each command and confirm it exists in the PATH
# --------------------------------------------------------------------------------------------
for cmd in "${commands[@]}"; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "ERROR: $cmd is not found in the current PATH."
    all_found=false
  else
    echo "NOTE: $cmd is found in the current PATH."
  fi
done

# --------------------------------------------------------------------------------------------
# Exit if any required command is missing
# --------------------------------------------------------------------------------------------
if [ "$all_found" = true ]; then
  echo "NOTE: All required commands are available."
else
  echo "ERROR: One or more required commands are missing."
  exit 1
fi

# ============================================================================================
# STEP 1: VALIDATE REQUIRED ENVIRONMENT VARIABLES
# ============================================================================================

echo "NOTE: Validating that required environment variables are set."

# List of required Azure environment variables
required_vars=(
  "ARM_CLIENT_ID"
  "ARM_CLIENT_SECRET"
  "ARM_SUBSCRIPTION_ID"
  "ARM_TENANT_ID"
)

# Flag to track validation status
all_set=true

# --------------------------------------------------------------------------------------------
# Loop through each variable and confirm it is set and non-empty
# --------------------------------------------------------------------------------------------
for var in "${required_vars[@]}"; do
  if [ -z "${!var}" ]; then
    echo "ERROR: $var is not set or is empty."
    all_set=false
  else
    echo "NOTE: $var is set."
  fi
done

# --------------------------------------------------------------------------------------------
# Exit if any required variable is missing
# --------------------------------------------------------------------------------------------
if [ "$all_set" = true ]; then
  echo "NOTE: All required environment variables are set."
else
  echo "ERROR: One or more environment variables are missing."
  exit 1
fi

# ============================================================================================
# STEP 2: VALIDATE AZURE LOGIN (SERVICE PRINCIPAL)
# ============================================================================================

echo "NOTE: Logging in to Azure using Service Principal..."

az login \
  --service-principal \
  --username "$ARM_CLIENT_ID" \
  --password "$ARM_CLIENT_SECRET" \
  --tenant "$ARM_TENANT_ID" \
  > /dev/null 2>&1

# --------------------------------------------------------------------------------------------
# Check return code of Azure login and report status
# --------------------------------------------------------------------------------------------
if [ $? -ne 0 ]; then
  echo "ERROR: Azure login failed. Verify credentials and environment variables."
  exit 1
else
  echo "NOTE: Successfully logged into Azure."
fi
