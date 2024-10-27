packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "region" {
  type    = string
  default = "us-east-1"
}

# Common builder configuration
locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
  common_tags = {
    Created     = local.timestamp
    Environment = "production"
    Name        = "buildkit-ami"
  }
}

# X86_64 Builder
source "amazon-ebs" "buildkit-x86" {
  ami_name      = "buildkit-x86-${local.timestamp}"
  instance_type = "t2.micro"
  region        = var.region
  source_ami    = "ami-06b21ccaeff8cd686" # Amazon Linux 2023 x86_64
  ssh_username  = "ec2-user"
  tags          = merge(local.common_tags, { Architecture = "x86_64" })
}

# ARM64 Builder
source "amazon-ebs" "buildkit-arm64" {
  ami_name      = "buildkit-arm64-${local.timestamp}"
  instance_type = "t4g.micro"
  region        = var.region
  source_ami    = "ami-02801556a781a4499" # Amazon Linux 2023 ARM64
  ssh_username  = "ec2-user"
  tags          = merge(local.common_tags, { Architecture = "arm64" })
}

# Build configuration
build {
  sources = [
    "source.amazon-ebs.buildkit-x86",
    "source.amazon-ebs.buildkit-arm64"
  ]

  provisioner "shell" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y docker git",
      "sudo systemctl start docker",
      "sudo systemctl enable docker",
      "sudo usermod -aG docker ec2-user"
    ]
  }

  provisioner "shell" {
    inline = [
      "BUILDKIT_VERSION=0.16.0",
      "ARCH=$(uname -m)",
      "if [ \"$ARCH\" = \"x86_64\" ]; then",
      "  BUILDKIT_FILE=\"buildkit-v$BUILDKIT_VERSION.linux-amd64.tar.gz\"",
      "else",
      "  BUILDKIT_FILE=\"buildkit-v$BUILDKIT_VERSION.linux-arm64.tar.gz\"",
      "fi",
      "sudo curl -sSL \"https://github.com/moby/buildkit/releases/download/v$BUILDKIT_VERSION/$BUILDKIT_FILE\" -o buildkit.tar.gz",
      "sudo tar -xzf buildkit.tar.gz -C /usr/local/bin --strip-components=1"
    ]
  }

  provisioner "shell" {
    inline = [
      "curl -fsSL https://tailscale.com/install.sh | sudo sh"
    ]
  }

  provisioner "file" {
    content     = <<EOF
[Unit]
Description=BuildKit daemon
After=network.target

[Service]
ExecStart=/usr/local/bin/buildkitd --addr tcp://0.0.0.0:9999 --addr unix:///run/buildkit/buildkitd.sock --debug
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    destination = "/tmp/buildkitd.service"
  }

  provisioner "shell" {
    inline = [
      "sudo mv /tmp/buildkitd.service /etc/systemd/system/buildkitd.service",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable buildkitd"
    ]
  }
}
