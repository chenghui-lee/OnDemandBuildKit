variable "iam_instance_profile" {
  description = "The IAM instance profile for EC2"
  type        = string
}

variable "tailscale_auth_key_x86" {
  description = "Tailscale auth key for x86_64 runner"
  type        = string
  sensitive   = true
}

variable "tailscale_auth_key_arm64" {
  description = "Tailscale auth key for arm64 runner"
  type        = string
  sensitive   = true
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID of the security group"
  type        = string
}
