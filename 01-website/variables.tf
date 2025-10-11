# ==============================================================================
# FILE: variables.tf
# PURPOSE:
#   - Define input variables required for the Terraform configuration
#   - Centralize domain configuration for Route 53 and related resources
# ==============================================================================

# ==============================================================================
# VARIABLE: Domain Name
# ==============================================================================
# Defines the fully-qualified domain name associated with the Route 53 hosted zone.
# This value is used across multiple modules (e.g., ACM, CloudFront, S3) to
# ensure consistent naming and DNS resolution.
#
# Example:
#   mikes-cloud-solutions.org.
#
# NOTE:
#   - Include the trailing dot (.) to match the format returned by Route 53.
#   - Replace the default value with your actual registered domain name.
# ------------------------------------------------------------------------------
variable "domain_name" {
  description = "Fully-qualified domain name of the Route 53 hosted zone (e.g., mikes-cloud-solutions.org.)"
  type        = string
  #default     = "mikes-cloud-solutions.com."  # Replace with your domain name
}
