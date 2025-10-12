#!/bin/bash
#================================================================================
# Script: apply.sh
# Purpose:
#   - Validate environment prerequisites
#   - Set AWS region for Terraform operations
#   - Initialize and apply Terraform to provision S3-based website 
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

export AWS_DEFAULT_REGION="us-east-1"
echo "NOTE: AWS default region set to ${AWS_DEFAULT_REGION}"

#--------------------------------------------------------------------------------
# 3. Build Website with S3 with HTTPS
#--------------------------------------------------------------------------------

echo "NOTE: Building website with S3..."

cd 01-website

terraform init
terraform apply -auto-approve

cd ..

echo "NOTE: Website provisioning complete."
#================================================================================

#az afd custom-domain show \
#  --profile-name mcs-fd-profile \
#  --resource-group mikes-solutions-org \
#  --custom-domain-name mcs-root-domain \
#  --query "tls"

#az afd custom-domain show \
#  --profile-name mcs-fd-profile \
#  --resource-group mikes-solutions-org \
#  --custom-domain-name mcs-www-domain \
#  --query "tls"