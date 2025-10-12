# ============================================================================================
# FILE: variables.tf
# PURPOSE:
#   - Define input variables required for the Terraform configuration
#   - Centralize domain configuration for Azure DNS and related resources
# ============================================================================================

# ============================================================================================
# VARIABLE: Domain Name
# ============================================================================================
# Defines the fully qualified domain name (FQDN) of the Azure DNS zone.
# This value is used across multiple resources (e.g., DNS records, web apps)
# to maintain consistent naming and DNS resolution.
#
# Example:
#   mikes-cloud-solutions.org
#
# NOTE:
#   - Do NOT include a trailing dot (.) as Azure DNS zones are stored without it.
#   - Replace the default value with your actual registered domain name.
# --------------------------------------------------------------------------------------------
variable "domain_name" {
  description = "Fully qualified domain name of the Azure DNS zone (e.g., mikes-cloud-solutions.org)"
  type        = string
  default   = "mikes-cloud-solutions.org"  # Replace with your domain
}

# ============================================================================================
# VARIABLE: Resource Group Name
# ============================================================================================
# Specifies the name of the Azure resource group that contains the existing
# DNS zone. This allows Terraform to locate and reference the zone directly.
# --------------------------------------------------------------------------------------------
variable "dns_resource_group" {
  description = "Name of the Azure resource group containing the DNS zone"
  type        = string
  default    = "mikes-solutions-org"  # Replace with your resource group name
}

# ============================================================================================
# DATA SOURCE: EXISTING AZURE DNS ZONE
# ============================================================================================
# Retrieves metadata for an existing DNS zone that was created manually
# in the Azure Portal. This enables Terraform to manage records within
# the same DNS zone without re-creating it.
# --------------------------------------------------------------------------------------------
data "azurerm_dns_zone" "existing_zone" {
  name                = var.domain_name
  resource_group_name = var.dns_resource_group
}

variable "web_location" {
  description = "Azure region where the web resources will be provisioned"
  type        = string
  default     = "Central US"  
}
