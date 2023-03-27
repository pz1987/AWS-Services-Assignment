# Create an IAM policy to allow EC2 instances to authenticate with AD or Azure AD
resource "aws_iam_policy" "ad_policy" {
  name = "AD_Policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:UpdateInstanceInformation"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2messages:AcknowledgeMessage",
          "ec2messages:DeleteMessage",
          "ec2messages:FailMessage",
          "ec2messages:GetEndpoint",
          "ec2messages:GetMessages",
          "ec2messages:SendReply"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach the IAM policy to the EC2 instances' IAM role
resource "aws_iam_role_policy_attachment" "ad_policy_attachment" {
  policy_arn = aws_iam_policy.ad_policy.arn
  role       = aws_iam_instance_profile.my_instance_profile.name
}

# Create an IAM instance profile for the EC2 instances
resource "aws_iam_instance_profile" "my_instance_profile" {
  #name = "My-Instance-Profile"
  name = "my_instance_profile"
  #role = aws_iam_role.my_role.name
  role = aws_iam_role.lambda_role.name
  #role = aws_iam_role.my_iam_role.name
  
}
