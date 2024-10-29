resource "random_shuffle" "subnet_ids" {
  input        = var.subnet_ids
  result_count = 1
}

resource "aws_instance" "buildkit-x86" {
  count         = 1
  ami           = "ami-042b5d19ec787c797"
  instance_type = "c7i-flex.2xlarge" # 8 core, 16GB, $0.1189/hour spot
  # availability_zone = "us-east-1a"
  instance_market_options {
    market_type = "spot"
  }

  associate_public_ip_address = true

  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = var.iam_instance_profile
  subnet_id              = random_shuffle.subnet_ids.result[0]

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
  }

  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Login tailscale
    tailscale up --authkey ${var.tailscale_auth_key_x86} --ssh
  EOF
}

resource "aws_instance" "buildkit-arm64" {
  count         = 1
  ami           = "ami-0917f168b0f1e4c7d"
  instance_type = "c8g.2xlarge" # 8 core, 16GB, $0.0458/hour spot
  # availability_zone = "us-east-1a"
  instance_market_options {
    market_type = "spot"
  }

  associate_public_ip_address = true

  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = var.iam_instance_profile
  subnet_id              = random_shuffle.subnet_ids.result[0]

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
  }

  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Login tailscale
    tailscale up --authkey ${var.tailscale_auth_key_arm64} --ssh
  EOF
}
