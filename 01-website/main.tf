# ==============================================================================
# FILE: main.tf
# PURPOSE:
#   - Configure AWS provider settings for Terraform
#   - Define the default region for resource deployment
#   - Define a secondary aliased provider for ACM and CloudFront (us-east-1)
# ==============================================================================
# REQUIREMENTS:
#   - AWS credentials must be properly configured (via CLI, environment variables,
#     or IAM role attached to the instance)
#   - Ensure the region matches your deployment target
# ==============================================================================

# ==============================================================================
# AWS PROVIDER CONFIGURATION
# ==============================================================================
# Establishes the default AWS provider used by Terraform for managing resources.
# The region determines where all AWS infrastructure will be created unless
# explicitly overridden by a provider alias.
# ------------------------------------------------------------------------------
provider "aws" {
  region = "us-east-1"  # Default region (US East - N. Virginia)
}

# ==============================================================================
# DATA BLOCK: Retrieve Route 53 Hosted Zone
# ==============================================================================
# Resolves the hosted zone for the target domain. This ensures that all DNS
# records, certificates, and alias mappings reference the correct Route 53 zone.
# ------------------------------------------------------------------------------
data "aws_route53_zone" "selected" {
  name         = var.domain_name  # Example: "mikes-cloud-solutions.org."
  private_zone = false            # Set to true if working with a private hosted zone
}

# ==============================================================================
# ALIASED PROVIDER: us-east-1 (Required for CloudFront / ACM)
# ==============================================================================
# CloudFront and ACM certificates used by CloudFront must be created in the
# us-east-1 region, even if your primary region is different. This alias allows
# Terraform to manage those resources correctly.
# ------------------------------------------------------------------------------
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
