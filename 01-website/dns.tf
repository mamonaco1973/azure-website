
# ================================================================================================
# A RECORD - ROOT DOMAIN (Front Door endpoint)
# ================================================================================================
resource "azurerm_dns_a_record" "root" {
  name                = "@"
  zone_name           = data.azurerm_dns_zone.existing_zone.name
  resource_group_name = var.dns_resource_group
  ttl                 = 300
  target_resource_id  = azurerm_cdn_frontdoor_endpoint.fd_endpoint.id
}

# ================================================================================================
# CNAME RECORD - WWW DOMAIN (optional)
# ================================================================================================
resource "azurerm_dns_cname_record" "www" {
  name                = "www"
  zone_name           = data.azurerm_dns_zone.existing_zone.name
  resource_group_name = var.dns_resource_group
  ttl                 = 300
  record              = azurerm_cdn_frontdoor_endpoint.fd_endpoint.host_name
}
