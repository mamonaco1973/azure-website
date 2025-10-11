# ==============================================================================
# FILE: bucket.tf
# PURPOSE:
#   - Provision a private S3 bucket to store static website content
#   - Upload a local "index.html" page to the bucket
#   - Apply encryption, versioning, and access restrictions
#   - Grant CloudFront Origin Access Control (OAC) permission to read objects
# ==============================================================================
# REQUIREMENTS:
#   - AWS CLI and Terraform properly configured
#   - CloudFront distribution resource must be defined for OAC reference
# ==============================================================================

# ==============================================================================
# DATA: Retrieve AWS Account Info
# ==============================================================================
# Retrieves the AWS account identity of the current credentials.
# This is used to generate a globally unique S3 bucket name.
# ------------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

# ==============================================================================
# LOCALS: Build Valid, Unique Bucket Name
# ==============================================================================
# Constructs an S3-compliant, globally unique bucket name by:
#   1. Replacing dots in the domain name with dashes
#   2. Appending the AWS account ID for uniqueness
# ------------------------------------------------------------------------------
locals {
  # Replace dots with dashes to comply with S3 DNS rules
  normalized_domain = replace(var.domain_name, ".", "-")

  # Combine normalized domain with account ID for uniqueness
  bucket_name = "${local.normalized_domain}${data.aws_caller_identity.current.account_id}"
}

# ==============================================================================
# S3 BUCKET: Private Website Content Bucket
# ==============================================================================
# Creates a private S3 bucket for static website content. The bucket name
# is generated dynamically to ensure global uniqueness across AWS.
# ------------------------------------------------------------------------------
resource "aws_s3_bucket" "website" {
  bucket = local.bucket_name

  # ---------------------------------------------------------------------------
  # Tagging for console identification and cost allocation
  # ---------------------------------------------------------------------------
  tags = {
    Name = local.bucket_name
  }
}

# ==============================================================================
# ENABLE VERSIONING
# ==============================================================================
# Enables versioning on the S3 bucket to preserve historical versions of files.
# This provides rollback capability and safeguards against accidental deletion.
# ------------------------------------------------------------------------------
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.website.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ==============================================================================
# ENABLE DEFAULT SERVER-SIDE ENCRYPTION (AES256)
# ==============================================================================
# Ensures all uploaded objects are automatically encrypted using the AES256
# algorithm to meet baseline security and compliance requirements.
# ------------------------------------------------------------------------------
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.website.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ==============================================================================
# BLOCK ALL PUBLIC ACCESS
# ==============================================================================
# Prevents direct public access to the bucket and its contents.
# CloudFront (with OAC) will handle HTTPS delivery securely.
# ------------------------------------------------------------------------------
resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ==============================================================================
# S3 OBJECT: Upload index.html
# ==============================================================================
# Uploads a local "index.html" file to the S3 bucket. This serves as the
# default page for the static site. The content type and cache behavior
# are explicitly defined for optimal browser delivery.
# ------------------------------------------------------------------------------
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.website.id
  key          = "index.html"                       # Object key inside the bucket
  source       = "${path.module}/index.html"        # Local file path
  etag         = filemd5("${path.module}/index.html")
  content_type = "text/html"

  # ---------------------------------------------------------------------------
  # Optional: Define caching behavior for browsers and CDNs
  # ---------------------------------------------------------------------------
  cache_control = "max-age=300"

  # ---------------------------------------------------------------------------
  # Optional: Tag for visibility and audit tracking
  # ---------------------------------------------------------------------------
  tags = {
    Name = "index.html"
  }
}

# ==============================================================================
# S3 BUCKET POLICY: Allow CloudFront OAC to Access Bucket
# ==============================================================================
# Grants the CloudFront distribution (via Origin Access Control) permission
# to retrieve objects from this S3 bucket. This ensures secure access
# through CloudFront without making the bucket public.
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "s3_oac_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.website.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.cdn.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "website_policy" {
  bucket = aws_s3_bucket.website.id
  policy = data.aws_iam_policy_document.s3_oac_policy.json
}
