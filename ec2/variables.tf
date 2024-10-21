variable "iam_instance_profile" {
  description = "The IAM instance profile for EC2"
  type        = string
}

variable "tailscale_auth_key" {
  description = "Tailscale auth key"
  type        = string
  sensitive   = true
}
