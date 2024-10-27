resource "aws_instance" "buildkit-x86" {
  ami           = "ami-042b5d19ec787c797"
  instance_type = "c7i-flex.2xlarge" # 8 core, 16GB, $0.1189/hour spot
  # availability_zone = "us-east-1a"
  instance_market_options {
    market_type = "spot"
  }

  associate_public_ip_address = false # Disable public IP

  vpc_security_group_ids = [aws_security_group.buildkit.id]
  iam_instance_profile   = var.iam_instance_profile

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
  }

  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Login tailscale
    tailscale up --authkey ${var.tailscale_auth_key_x86}
  EOF
}

resource "aws_instance" "buildkit-arm64" {
  ami           = "ami-0917f168b0f1e4c7d"
  instance_type = "c8g.2xlarge" # 8 core, 16GB, $0.0458/hour spot
  # availability_zone = "us-east-1a"
  instance_market_options {
    market_type = "spot"
  }

  associate_public_ip_address = false # Disable public IP

  vpc_security_group_ids = [aws_security_group.buildkit.id]
  iam_instance_profile   = var.iam_instance_profile

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
  }

  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Login tailscale
    tailscale up --authkey ${var.tailscale_auth_key_arm64}
  EOF
}

resource "aws_security_group" "buildkit" {
  name        = "buildkit-sg"
  description = "Security group for BuildKit instance"

  ingress {
    from_port   = 9999
    to_port     = 9999
    protocol    = "tcp"
    cidr_blocks = ["100.64.0.0/10"] # Tailscale VPN CIDR
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
