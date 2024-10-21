# EC2 Instance for BuildKit

resource "aws_instance" "buildkit" {
  ami               = "ami-06b21ccaeff8cd686"
  instance_type     = "c5a.large"
  availability_zone = "us-east-1a"

  vpc_security_group_ids = [aws_security_group.buildkit.id]
  iam_instance_profile   = aws_iam_instance_profile.buildkit_instance_profile.name

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
    export BUILDKIT_VERSION=0.12.0
    curl -sSL "https://github.com/moby/buildkit/releases/download/v$${BUILDKIT_VERSION}/buildkit-v$${BUILDKIT_VERSION}.linux-amd64.tar.gz" -o buildkit.tar.gz
    tar -xzf buildkit.tar.gz -C /usr/local/bin --strip-components=1

    # Install tailscale VPN
    curl -fsSL https://tailscale.com/install.sh | sh

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

  depends_on = [
    aws_iam_instance_profile.buildkit_instance_profile
  ]
}

# Security Group for BuildKit Instance
resource "aws_security_group" "buildkit" {
  name        = "buildkit-sg"
  description = "Security group for BuildKit instance"


  ingress {
    from_port   = 9999
    to_port     = 9999
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict this to GA runners range
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# IAM Role for EC2 Instance
resource "aws_iam_role" "buildkit_instance_role" {
  name = "BuildKitInstanceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Role Policy Attachment
resource "aws_iam_role_policy_attachment" "buildkit_instance_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
  role       = aws_iam_role.buildkit_instance_role.name
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "buildkit_instance_profile" {
  name = "BuildKitInstanceProfile"
  role = aws_iam_role.buildkit_instance_role.name
}

# Output
output "buildkit_instance_public_ip" {
  value       = aws_instance.buildkit.public_ip
  description = "The public IP address of the BuildKit instance"
}
