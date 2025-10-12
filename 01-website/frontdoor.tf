# ============================================================================================
# FRONT DOOR PROFILE
# ============================================================================================
resource "azurerm_cdn_frontdoor_profile" "fd_profile" {
  name                = "mcs-fd-profile"
  resource_group_name = azurerm_resource_group.website_rg.name
  sku_name            = "Standard_AzureFrontDoor"
}

# ============================================================================================
# FRONT DOOR ENDPOINT
# ============================================================================================
resource "azurerm_cdn_frontdoor_endpoint" "fd_endpoint" {
  name                     = "mcs-fd-endpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd_profile.id
}

# ============================================================================================
# FRONT DOOR ORIGIN GROUP AND ORIGIN (Storage Account)
# ============================================================================================
# Defines the origin group and origin used by Azure Front Door.
# The origin group requires load_balancing and health_probe blocks.
# --------------------------------------------------------------------------------------------
resource "azurerm_cdn_frontdoor_origin_group" "fd_group" {
  name                     = "mcs-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd_profile.id
  session_affinity_enabled = false

  # ------------------------------------------------------------------------------------------
  # Load balancing configuration (basic single-origin setup)
  # ------------------------------------------------------------------------------------------
  load_balancing {
    sample_size                 = 4
    successful_samples_required = 2
  }

  # ------------------------------------------------------------------------------------------
  # Health probe configuration (Front Door checks origin health)
  # ------------------------------------------------------------------------------------------
  health_probe {
    interval_in_seconds = 120
    path                = "/"
    protocol            = "Https"
    request_type        = "HEAD"
  }
}

# ============================================================================================
# FRONT DOOR ORIGIN (Storage Account)
# ============================================================================================
# Defines the backend origin for the Front Door endpoint.
# Removes both "https://" and any trailing slash from the static website URL.
# --------------------------------------------------------------------------------------------
locals {
  # Remove "https://" first, then trim trailing "/"
  storage_origin_host = replace(
    replace(azurerm_storage_account.sa.primary_web_endpoint, "https://", ""),
    "/",
    ""
  )
}

# ============================================================================================
# FRONT DOOR ORIGIN (Storage Account)
# ============================================================================================
# Defines the backend origin for the Front Door endpoint.
# The origin uses the Azure Storage static website endpoint.
# --------------------------------------------------------------------------------------------
resource "azurerm_cdn_frontdoor_origin" "fd_origin" {
  name                          = "mcs-storage-origin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.fd_group.id
  enabled                       = true
  host_name                     = local.storage_origin_host
  origin_host_header            = local.storage_origin_host
  http_port                     = 80
  https_port                    = 443
  priority                      = 1
  weight                        = 1000
  certificate_name_check_enabled = true
}

# ============================================================================================
# FRONT DOOR ROUTE - MAP TRAFFIC TO STORAGE
# ============================================================================================
# Binds the endpoint to the origin group and specific origin(s).
# --------------------------------------------------------------------------------------------
resource "azurerm_cdn_frontdoor_route" "fd_route" {
  name                          = "mcs-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.fd_endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.fd_group.id

  # At least one origin ID is required (not just the group).
  cdn_frontdoor_origin_ids = [
    azurerm_cdn_frontdoor_origin.fd_origin.id
  ]

  patterns_to_match      = ["/*"]
  https_redirect_enabled = true
  supported_protocols    = ["Http", "Https"]
  link_to_default_domain = true
  enabled                = true
}

# ================================================================================================
# FRONT DOOR CUSTOM DOMAIN - ROOT (mikes-cloud-solutions.net)
# ================================================================================================
resource "azurerm_cdn_frontdoor_custom_domain" "fd_custom_domain_root" {
  name                     = "mcs-root-domain"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd_profile.id
  host_name                = var.domain_name
  dns_zone_id              = azurerm_dns_zone.main.id

  # ----------------------------------------------------------------------------------------------
  # TLS block is now required in the azurerm_cdn_frontdoor_custom_domain resource.
  # "certificate_type = ManagedCertificate" tells Azure to issue and bind a cert automatically.
  # ----------------------------------------------------------------------------------------------
  tls {
    certificate_type    = "ManagedCertificate"
  }
}
