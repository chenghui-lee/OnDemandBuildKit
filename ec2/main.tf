resource "aws_instance" "buildkit" {
  ami           = "ami-077031ab126ca0f2c"
  instance_type = "c7i-flex.4xlarge" # 16 core, 32GB, 0.2432/hour spot
  # availability_zone = "us-east-1a"
  instance_market_options {
    market_type = "spot"
  }

  associate_public_ip_address = false # Disable public IP

  vpc_security_group_ids = [aws_security_group.buildkit.id]
  iam_instance_profile   = var.iam_instance_profile

  root_block_device {
    volume_type = "gp3"
    volume_size = 50
  }

  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Login tailscale
    tailscale up --authkey ${var.tailscale_auth_key}
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

output "ec2_public_ip" {
  value = aws_instance.buildkit.public_ip
}
