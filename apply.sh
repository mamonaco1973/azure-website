#!/bin/bash
#================================================================================
# Script: apply.sh
# Purpose:
#   - Validate environment prerequisites
#   - Initialize and apply Terraform to provision Azure based website 
#================================================================================

#--------------------------------------------------------------------------------
# 0. StrictErrorHandling
#--------------------------------------------------------------------------------
set -euo pipefail
IFS=$'\n\t'

#--------------------------------------------------------------------------------
# 1. Validate the Environment
#--------------------------------------------------------------------------------

echo "NOTE: Running environment validation..."
./check_env.sh

if [ $? -ne 0 ]; then
    echo "ERROR: Environment check failed. Exiting."
    exit 1
fi

#--------------------------------------------------------------------------------
# 3. Build Website in Azure with HTTPS
#--------------------------------------------------------------------------------

echo "NOTE: Building Simple Website in Azure..."

cd 01-website

terraform init
terraform apply -auto-approve

cd ..

echo "NOTE: Website provisioning complete."

#--------------------------------------------------------------------------------
# 4. Validate that the website is reachable
#--------------------------------------------------------------------------------

./validate.sh