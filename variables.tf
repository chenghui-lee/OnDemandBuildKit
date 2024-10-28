variable "region" {
  description = "The AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "The name of the S3 bucket for build cache"
  type        = string
}

variable "tailscale_auth_key_x86" {
  description = "The Tailscale auth key for x86_64 runner"
  type        = string
}

variable "tailscale_auth_key_arm64" {
  description = "The Tailscale auth key for arm64 runner"
  type        = string
}
