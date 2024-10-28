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

# IAM Role Policy Attachment for ECR Access
resource "aws_iam_role_policy_attachment" "buildkit_instance_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
  role       = aws_iam_role.buildkit_instance_role.name
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "buildkit_instance_profile" {
  name = "BuildKitInstanceProfile"
  role = aws_iam_role.buildkit_instance_role.name
}
