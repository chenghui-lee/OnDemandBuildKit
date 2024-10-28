resource "aws_security_group" "buildkit" {
  name        = "buildkit-sg"
  description = "Security group for BuildKit instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 9999
    to_port     = 9999
    protocol    = "tcp"
    cidr_blocks = ["100.64.0.0/10"] # Tailscale VPN CIDR
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["100.64.0.0/10"] # temporary allow SSH from anywhere, should be restricted
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
