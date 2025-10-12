# ============================================================================================
# LOCALS - DERIVE STORAGE ACCOUNT NAME
# ============================================================================================
# Azure storage names:
#   - Must be 3–24 chars, lowercase letters or numbers only
#   - No dots, hyphens, or uppercase letters
#   - Append random suffix for uniqueness
# --------------------------------------------------------------------------------------------
locals {
  # Sanitize domain: remove dots and hyphens, convert to lowercase
  base_name = lower(replace(replace(var.domain_name, ".", ""), "-", ""))

  # Truncate to 15 chars and append random 5-char suffix
  storage_name = format(
    "%s%s",
    substr(local.base_name, 0, 15),
    random_string.suffix.result
  )
}

# ============================================================================================
# RANDOM STRING - UNIQUE SUFFIX
# ============================================================================================
resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
}

# ============================================================================================
# STORAGE ACCOUNT - STATIC WEBSITE HOSTING
# ============================================================================================
# Creates an Azure Storage Account for hosting static website content.
# Requirements:
#   - Name: must be 3–24 chars, lowercase letters or numbers only
#   - Account type: Standard_LRS (cost-effective for single region)
#   - Public access: required for static website endpoint
# --------------------------------------------------------------------------------------------
resource "azurerm_storage_account" "sa" {
  name                     = local.storage_name
  resource_group_name      = data.azurerm_resource_group.website_rg.name
  location                 = data.azurerm_resource_group.website_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# ============================================================================================
# STATIC WEBSITE (CORRECT FIELDS)
# ============================================================================================
resource "azurerm_storage_account_static_website" "site" {
  storage_account_id = azurerm_storage_account.sa.id
  index_document     = "index.html"
  error_404_document = "404.html"
}

# ============================================================================================
# UPLOAD LOCAL WEBSITE FILES TO AZURE STORAGE ($web)
# ============================================================================================
# Uploads existing index.html and 404.html files in the current directory to
# the special $web container used for static website hosting.
# --------------------------------------------------------------------------------------------
resource "azurerm_storage_blob" "index_html" {
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = "$web"
  type                   = "Block"
  source                 = "${path.module}/index.html"
  content_type           = "text/html"
  depends_on             = [azurerm_storage_account_static_website.site]
}

resource "azurerm_storage_blob" "error_html" {
  name                   = "404.html"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = "$web"
  type                   = "Block"
  source                 = "${path.module}/404.html"
  content_type           = "text/html"
  depends_on             = [azurerm_storage_account_static_website.site]
}
