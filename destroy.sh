#!/bin/bash
#================================================================================
# Script: destroy.sh
# Purpose:
#   - Destroy all AWS S3 website infrastructure previously provisioned
#   - Ensure clean teardown of Terraform-managed resources in the 01-website dir
#================================================================================

#--------------------------------------------------------------------------------
# 0. Strict Error Handling
#--------------------------------------------------------------------------------
set -euo pipefail
IFS=$'\n\t'

#--------------------------------------------------------------------------------
# 1. Set Default AWS Region
#--------------------------------------------------------------------------------
export AWS_DEFAULT_REGION="us-east-1"
echo "NOTE: AWS default region set to ${AWS_DEFAULT_REGION}"

#--------------------------------------------------------------------------------
# 2. Destroy Website Infrastructure (01-website)
#--------------------------------------------------------------------------------
echo "NOTE: Starting destruction of website infrastructure..."

cd 01-website

terraform init
terraform destroy -auto-approve

cd ..

#--------------------------------------------------------------------------------
# 3. Completion
#--------------------------------------------------------------------------------
echo "NOTE: Website infrastructure destruction complete."
#================================================================================
