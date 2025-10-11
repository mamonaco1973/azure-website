# ==============================================================================
# FILE: acm.tf
# PURPOSE:
#   - Request and validate an AWS ACM certificate for the specified domain
#   - Automatically create DNS validation records in Route 53
#   - Supports both root and wildcard domain names for CloudFront use
# ==============================================================================
# REQUIREMENTS:
#   - Route 53 hosted zone must already exist for the target domain
#   - Provider alias "aws.us_east_1" must be defined (for CloudFront compatibility)
# ==============================================================================

# ==============================================================================
# LOCALS: Normalize Domain Name (remove trailing dot)
# ==============================================================================
# Route 53 zone names often end with a trailing dot (e.g., "example.com.").
# This trims the suffix so domain names are cleanly formatted in downstream use.
# ------------------------------------------------------------------------------
locals {
  root_domain = trimsuffix(data.aws_route53_zone.selected.name, ".")
}

# ==============================================================================
# ACM CERTIFICATE: Wildcard + Root Domain
# ==============================================================================
# Requests an ACM certificate in us-east-1 (required region for CloudFront).
# Covers both:
#   - Root domain (example.com)
#   - Wildcard subdomain (*.example.com)
# ------------------------------------------------------------------------------
resource "aws_acm_certificate" "site_cert" {
  provider                  = aws.us_east_1
  domain_name               = local.root_domain
  subject_alternative_names = ["*.${local.root_domain}"]
  validation_method         = "DNS"

  # ---------------------------------------------------------------------------
  # Lifecycle configuration:
  #   - create_before_destroy ensures continuity during certificate rotation
  #   - ignore_changes avoids recreation if SAN list order changes
  # ---------------------------------------------------------------------------
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [subject_alternative_names]
  }

  # ---------------------------------------------------------------------------
  # Tagging for AWS Console visibility
  # ---------------------------------------------------------------------------
  tags = {
    Name = "Wildcard-${local.root_domain}"
  }
}

# ==============================================================================
# DNS VALIDATION RECORDS (Use the same Hosted Zone)
# ==============================================================================
# For each domain validation option provided by ACM, create a corresponding
# CNAME record in the same Route 53 zone. These records confirm domain ownership
# and allow ACM to automatically validate the certificate.
# ------------------------------------------------------------------------------
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.site_cert.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone_id = data.aws_route53_zone.selected.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 300
  records = [each.value.value]

  # ---------------------------------------------------------------------------
  # Allow Terraform to safely overwrite validation records if they already exist
  # ---------------------------------------------------------------------------
  allow_overwrite = true
}

# ==============================================================================
# VALIDATE CERTIFICATE
# ==============================================================================
# Waits for ACM to detect that DNS validation records exist and are resolvable.
# Once verified, the certificate is issued and ready for use with CloudFront
# or other AWS services that require an HTTPS endpoint.
# ------------------------------------------------------------------------------
resource "aws_acm_certificate_validation" "cert_validation" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.site_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# ==============================================================================
# OUTPUT: Website URL
# ==============================================================================
# Displays the full public website URL (HTTPS) after deployment.
# Uses the normalized domain without the trailing dot.
# ------------------------------------------------------------------------------
output "website_url" {
  description = "Public HTTPS URL for the deployed website"
  value       = "https://www.${local.root_domain}"
}