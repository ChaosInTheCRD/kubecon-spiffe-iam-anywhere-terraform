provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "spiffe_csi_test" {
  bucket = "spiffe-csi-test"

  tags = {
    Name        = "Spiffe CSI Bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_acl" "spiffe_csi_acl" {
  bucket = aws_s3_bucket.spiffe_csi_test.id
  acl    = "private"
}

resource "aws_rolesanywhere_trust_anchor" "cert_manager_spiffe" {
  name    = "cert-manager-spiffe"
  enabled = true

  source {
    source_data {
      x509_certificate_data = file("${path.module}/ca.crt")
    }
    source_type = "CERTIFICATE_BUNDLE"
  }
}

resource "aws_iam_role" "spiffe_iam_anywhere" {
  name = "spiffe_iam_anywhere"
  path = "/"

  assume_role_policy  = file("${path.module}/anywhere.json")
  managed_policy_arns = [aws_iam_policy.spiffe_s3_write.arn]
}

resource "aws_iam_policy" "spiffe_s3_write" {
  name = "spiffe_s3_write"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListObjects",
          "s3:DeleteObject"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_rolesanywhere_profile" "spiffe_s3_anywhere" {
  name      = "spiffe_s3_write"
  enabled   = true
  role_arns = [aws_iam_role.spiffe_iam_anywhere.arn]
}
