variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
}

variable "ec2_instance_role" {
  description = "The IAM role attached to the EC2 instance"
  type        = string
}
