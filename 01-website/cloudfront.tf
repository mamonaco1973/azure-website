# ==============================================================================
# FILE: cloudfront.tf
# PURPOSE:
#   - Configure CloudFront distribution for HTTPS web delivery
#   - Use Origin Access Control (OAC) for secure S3 access
#   - Associate custom domain names via ACM certificate
#   - Create Route 53 alias records for root and www hostnames
# ==============================================================================
# REQUIREMENTS:
#   - ACM certificate must already be issued and validated
#   - S3 bucket and website object must exist
#   - Route 53 hosted zone must be configured for the domain
# ==============================================================================

# ==============================================================================
# ORIGIN ACCESS CONTROL (OAC) - Secure S3 Access
# ==============================================================================
# Establishes a CloudFront Origin Access Control (OAC) that securely signs
# requests from CloudFront to S3 using SigV4. This replaces legacy OAI access.
# ------------------------------------------------------------------------------
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${local.root_domain}-oac"
  description                       = "OAC for ${local.root_domain} CloudFront distribution"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ==============================================================================
# CLOUD FRONT DISTRIBUTION - HTTPS Web Delivery
# ==============================================================================
# Configures CloudFront to serve the static website securely over HTTPS.
#   - Uses S3 as the origin (private bucket)
#   - Redirects all HTTP traffic to HTTPS
#   - Associates the ACM certificate for custom domain HTTPS
# ------------------------------------------------------------------------------
resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  default_root_object = "index.html"
  comment             = "Static site for ${local.root_domain}"

  # ---------------------------------------------------------------------------
  # ORIGIN CONFIGURATION - Connect to S3 bucket
  # ---------------------------------------------------------------------------
  origin {
    domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id                = "s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  # ---------------------------------------------------------------------------
  # DEFAULT CACHE BEHAVIOR - Redirect HTTP to HTTPS
  # ---------------------------------------------------------------------------
  default_cache_behavior {
    target_origin_id       = "s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  # ---------------------------------------------------------------------------
  # CUSTOM DOMAIN SETTINGS - Use ACM Certificate for HTTPS
  # ---------------------------------------------------------------------------
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cert_validation.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # ---------------------------------------------------------------------------
  # ALIASES - Custom Domain Mapping
  # ---------------------------------------------------------------------------
  aliases = [
    local.root_domain,             # e.g. mikes-cloud-solutions.com
    "www.${local.root_domain}"     # e.g. www.mikes-cloud-solutions.com
  ]

  # ---------------------------------------------------------------------------
  # GENERAL SETTINGS - Default global restrictions
  # ---------------------------------------------------------------------------
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # ---------------------------------------------------------------------------
  # Optimize pricing for North America and Europe
  # ---------------------------------------------------------------------------
  price_class = "PriceClass_100"

  # ---------------------------------------------------------------------------
  # Tags for traceability and cost tracking
  # ---------------------------------------------------------------------------
  tags = {
    Name        = "cdn-${local.root_domain}"
    Environment = "prod"
  }
}

# ==============================================================================
# ROUTE 53 ALIAS RECORD - www -> CloudFront
# ==============================================================================
# Creates a Route 53 alias record that maps the "www" subdomain
# to the CloudFront distribution domain. Alias records allow
# integration with CloudFront without needing IP addresses.
# ------------------------------------------------------------------------------
resource "aws_route53_record" "www_alias" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "www"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

# ==============================================================================
# ROUTE 53 ALIAS RECORD - Root Domain -> CloudFront
# ==============================================================================
# Creates a Route 53 alias record that maps the root (apex) domain
# directly to the CloudFront distribution. This enables HTTPS access
# at the naked domain (e.g., https://mikes-cloud-solutions.com).
# ------------------------------------------------------------------------------
resource "aws_route53_record" "root_alias" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = local.root_domain     # e.g. mikes-cloud-solutions.com
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}
