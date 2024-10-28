output "iam_role_name" {
  value = aws_iam_role.buildkit_instance_role.name
}

output "iam_instance_profile" {
  value = aws_iam_instance_profile.buildkit_instance_profile.name
}