# Create an IAM policy for Session Manager access
resource "aws_iam_policy" "session_manager_policy" {
  name_prefix = "session_manager_policy_"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssm:StartSession",
          "ssm:TerminateSession"
        ],
        Resource = "arn:aws:ec2:*:*:instance/${aws_instance.my_instance.id}"
      }
    ]
  })
}

# Create an IAM role for Session Manager access
resource "aws_iam_role" "session_manager_role" {
  name = "session_manager_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the IAM policy to the IAM role
resource "aws_iam_role_policy_attachment" "session_manager_role_policy_attachment" {
  policy_arn = aws_iam_policy.session_manager_policy.arn
  role       = aws_iam_role.session_manager_role.name
}

# Add the IAM role to the EC2 instance profile
resource "aws_iam_instance_profile" "my_instance_profile1" {
  name = "my_instance_profile1"

  #roles = [
  #  aws_iam_role.my_iam_role.name,
  #  aws_iam_role.session_manager_role.name
  #]
  role = aws_iam_role.session_manager_role.name
}

# Enable Session Manager for the EC2 instance
resource "aws_ssm_association" "session_manager_association" {
  name = "AWS-StartSSHSession"
  targets {
    key    = "InstanceIds"
    values = [aws_instance.my_instance.id]
  }
}