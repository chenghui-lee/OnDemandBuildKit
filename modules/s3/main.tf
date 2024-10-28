resource "aws_s3_bucket" "build_cache" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.build_cache.id
  versioning_configuration {
    status = "Disabled"
  }
}
resource "aws_s3_bucket_lifecycle_configuration" "delete_seven_days" {
  bucket = aws_s3_bucket.build_cache.id

  rule {
    id     = "housekeeping-rule"
    status = "Enabled"
    expiration {
      days = 7
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}


resource "aws_iam_policy" "s3_access_policy" {
  name = "${var.bucket_name}_s3_access_policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Effect = "Allow",
        Resource = [
          "arn:aws:s3:::${var.bucket_name}",
          "arn:aws:s3:::${var.bucket_name}/*"
        ]
      }
    ]
  })
}

resource "aws_s3_bucket_policy" "allow_access_from_vpc" {
  bucket = aws_s3_bucket.build_cache.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Access-to-specific-VPC-only"
        Effect = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          aws_s3_bucket.build_cache.arn,
          "${aws_s3_bucket.build_cache.arn}/*"
        ]
        Condition = {
          StringEquals = {
            "aws:sourceVpc": var.vpc_id
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_access_role_attachment" {
  role       = var.ec2_instance_role
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

output "bucket_name" {
  value = aws_s3_bucket.build_cache.bucket
}
