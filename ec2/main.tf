resource "aws_instance" "buildkit" {
  ami               = "ami-06b21ccaeff8cd686"
  instance_type     = "c5a.large"
  availability_zone = "us-east-1a"

  associate_public_ip_address = false  # Disable public IP

  vpc_security_group_ids = [aws_security_group.buildkit.id]
  iam_instance_profile   = var.iam_instance_profile

  root_block_device {
    volume_type = "gp3"
    volume_size = 13
  }

  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Update and install dependencies
    yum update -y
    yum install -y docker git

    # Start and enable Docker
    systemctl start docker
    systemctl enable docker

    # Add ec2-user to the docker group
    usermod -aG docker ec2-user

    # Download and install BuildKit
    export BUILDKIT_VERSION=0.16.0
    curl -sSL "https://github.com/moby/buildkit/releases/download/v$${BUILDKIT_VERSION}/buildkit-v$${BUILDKIT_VERSION}.linux-amd64.tar.gz" -o buildkit.tar.gz
    tar -xzf buildkit.tar.gz -C /usr/local/bin --strip-components=1

    # Install tailscale VPN
    curl -fsSL https://tailscale.com/install.sh | sh
    tailscale up --authkey ${var.tailscale_auth_key}

    # Create buildkitd systemd service
    cat <<EOT > /etc/systemd/system/buildkitd.service
    [Unit]
    Description=BuildKit daemon
    After=network.target

    [Service]
    ExecStart=/usr/local/bin/buildkitd --addr tcp://0.0.0.0:9999 --addr unix:///run/buildkit/buildkitd.sock --debug
    Restart=always

    [Install]
    WantedBy=multi-user.target
    EOT

    # Enable and start buildkitd service
    systemctl daemon-reload
    systemctl enable buildkitd
    systemctl start buildkitd
  EOF
}

resource "aws_security_group" "buildkit" {
  name        = "buildkit-sg"
  description = "Security group for BuildKit instance"

  ingress {
    from_port   = 9999
    to_port     = 9999
    protocol    = "tcp"
    cidr_blocks = ["100.64.0.0/10"]  # Tailscale VPN CIDR
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
