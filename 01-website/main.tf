# ============================================================================================
# AZURE PROVIDER CONFIGURATION
# ============================================================================================

# Configure the AzureRM provider for Terraform to interact with Azure services.
# The 'features' block must be declared even if empty — it enables provider defaults.
# --------------------------------------------------------------------------------------------
provider "azurerm" {
  features {}  # Required empty block (do not remove)
}

# ============================================================================================
# DATA SOURCES - AZURE CONTEXT
# ============================================================================================

# --------------------------------------------------------------------------------------------
# Retrieve subscription details (e.g., subscription_id, tenant_id, display_name).
# Useful for tagging, auditing, and linking resources to the subscription context.
# --------------------------------------------------------------------------------------------
data "azurerm_subscription" "primary" {}

# --------------------------------------------------------------------------------------------
# Retrieve authentication context for the current Azure CLI or Service Principal.
# Exposes object_id, client_id, and tenant_id for role or identity assignments.
# --------------------------------------------------------------------------------------------
data "azurerm_client_config" "current" {}

# ============================================================================================
# RESOURCE GROUP - PRIMARY CONTAINER
# ============================================================================================

# --------------------------------------------------------------------------------------------
# Defines the main resource group that will host all website infrastructure.
# The name must be unique within the Azure subscription.
# --------------------------------------------------------------------------------------------
data "azurerm_resource_group" "website_rg" {
  name = var.dns_resource_group
}