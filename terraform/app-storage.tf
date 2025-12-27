# Application version storage for Elastic Beanstalk deployments

#https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
resource "aws_s3_bucket" "app_versions" {
  #checkov:skip=CKV_AWS_18: "Access logging not required for demo application version storage"
  #checkov:skip=CKV2_AWS_62: "Event notifications not required for demo application version storage"
  #checkov:skip=CKV_AWS_144: "Cross-region replication not required for demo purposes"
  bucket        = "${var.name}-beanstalk-versions-${random_string.bucket_suffix.result}"
  force_destroy = true
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration
resource "aws_s3_bucket_server_side_encryption_configuration" "app_versions" {
  #checkov:skip=CKV_AWS_145: "Using AES256 encryption instead of KMS for demo simplicity"
  bucket = aws_s3_bucket.app_versions.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning
resource "aws_s3_bucket_versioning" "app_versions" {
  bucket = aws_s3_bucket.app_versions.id
  versioning_configuration {
    status = "Enabled"
  }
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration
resource "aws_s3_bucket_lifecycle_configuration" "app_versions" {
  bucket = aws_s3_bucket.app_versions.id

  rule {
    id     = "cleanup_old_versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block
resource "aws_s3_bucket_public_access_block" "app_versions" {
  bucket = aws_s3_bucket.app_versions.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file
data "archive_file" "app_zip" {
  type        = "zip"
  source_dir  = "../app"
  output_path = "../app.zip"
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object
resource "aws_s3_object" "app_version" {
  bucket = aws_s3_bucket.app_versions.bucket
  key    = "app-${data.archive_file.app_zip.output_md5}.zip"
  source = data.archive_file.app_zip.output_path
  etag   = data.archive_file.app_zip.output_md5
}