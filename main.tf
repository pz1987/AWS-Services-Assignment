
# Configure the AWS provider
provider "aws" {
  region = "us-east-1"
}

# Create a new VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "My VPC"
  }
}

# Create subnets for web, app, and database tiers
resource "aws_subnet" "web_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Web Subnet"
  }
}

resource "aws_subnet" "app_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "App Subnet"
  }
}

resource "aws_subnet" "db_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1c"

  tags = {
    Name = "DB Subnet"
  }
}

# Create a security group for the EC2 instances
resource "aws_security_group" "ec2_sg" {
  name_prefix = "ec2_sg_"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a security group for the Application Load Balancer
resource "aws_security_group" "alb_sg" {
  name_prefix = "alb_sg_"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an Application Load Balancer
resource "aws_lb" "my_lb" {
  name            = "My-Load-Balancer"
  internal        = true
  security_groups = [aws_security_group.alb_sg.id]
  subnets = [
    aws_subnet.web_subnet.id,
    aws_subnet.app_subnet.id
  ]

  tags = {
    Name = "My-Load-Balancer"
  }

  depends_on = [
    aws_lb_target_group.app_tg,
    aws_lb_target_group.web_tg
  ]
}

# Create target groups for the web and app tiers
resource "aws_lb_target_group" "web_tg" {
  name_prefix = "web-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.my_vpc.id

  health_check {
    path     = "/"
    interval = 30
    timeout  = 5
  }

  tags = {
    Name = "Web Target Group"
  }
}

resource "aws_lb_target_group" "app_tg" {
  name_prefix = "app-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.my_vpc.id

  health_check {
    path     = "/health"
    interval = 30
    timeout  = 5
  }

  tags = {
    Name = "App Target Group"
  }
}

# Create an Auto Scaling group
resource "aws_launch_configuration" "my_lc" {
  name_prefix     = "my_lc_"
  image_id        = "ami-123456"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.ec2_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello World" > index.html
              nohup python -m SimpleHTTPServer 80 &
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "my_asg" {
  name = "My Auto Scaling Group"
  vpc_zone_identifier = [
    aws_subnet.web_subnet.id,
    aws_subnet.app_subnet.id
  ]
  desired_capacity = 2
  min_size         = 2
  max_size         = 10

  launch_configuration = aws_launch_configuration.my_lc.name

  target_group_arns = [
    aws_lb_target_group.web_tg.arn,
    aws_lb_target_group.app_tg.arn
  ]

  #tags {
  #  Name = "MyAutoScalingGroup"
  #}
  tag {
    key                 = "name"
    value               = "MyAutoScalingGroup"
    propagate_at_launch = true
  }
}

# Create a CloudWatch alarm to scale out the Auto Scaling group
resource "aws_cloudwatch_metric_alarm" "scale_out_alarm" {
  alarm_name          = "Scale Out Alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "70"
  alarm_description   = "This metric monitors CPU utilization"
  alarm_actions = [
    aws_autoscaling_policy.scale_out_policy.arn
  ]
}

# Create a CloudWatch alarm to scale in the Auto Scaling group
resource "aws_cloudwatch_metric_alarm" "scale_in_alarm" {
  alarm_name          = "Scale In Alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "30"
  alarm_description   = "This metric monitors CPU utilization"
  alarm_actions = [
    aws_autoscaling_policy.scale_in_policy.arn
  ]
}

# Create scale out and scale in policies for the Auto Scaling group
resource "aws_autoscaling_policy" "scale_out_policy" {
  name            = "scale_out_policy_"
  policy_type            = "SimpleScaling"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "1"
  autoscaling_group_name = aws_autoscaling_group.my_asg.name
}

resource "aws_autoscaling_policy" "scale_in_policy" {
  name           = "scale_in_policy_"
  policy_type            = "SimpleScaling"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "-1"
  autoscaling_group_name = aws_autoscaling_group.my_asg.name
}

# Create an AWS Backup
resource "aws_backup_plan" "my_backup_plan" {
  name = "My_Backup_Plan"
  rule {
    rule_name         = "My_Backup_Rule"
    target_vault_name = "My_Backup_Vault"
    schedule          = "cron(0 10 * * ? *)"
    #schedule  {
    #  frequency  = "daily"
    #  start_time = "10:00"
    #}
    lifecycle {
      cold_storage_after = "90"
      delete_after       = "365"
    }
    recovery_point_tags = {
      Name = "My Backup Tag"
    }
  }
}

# Create a Lambda function to stop and start the EC2 instances
resource "aws_lambda_function" "my_lambda_function" {
  filename = "lambda_function.py"
  function_name = "my_lambda"
  role     = aws_iam_role.lambda_role.arn
  handler  = "lambda_function.lambda_handler"
  runtime  = "python3.8"
}

# Create an IAM role for the Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "Lambda_Role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the necessary IAM policies to the Lambda role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  role       = aws_iam_role.lambda_role.name
}

resource "aws_iam_role_policy_attachment" "cloudwatch_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
  role       = aws_iam_role.lambda_role.name
}

# Create a CloudWatch event to trigger the Lambda function
resource "aws_cloudwatch_event_rule" "stop_start_rule" {
  name                = "Stop_and_Start_Instances"
  schedule_expression = "cron(0 18 ? * MON-FRI *)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule = aws_cloudwatch_event_rule.stop_start_rule.name
  arn  = aws_lambda_function.my_lambda_function.arn
}

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
  name = "My-Instance-Profile"
  #role = aws_iam_role.my_role.name
  role = aws_iam_role.lambda_role.name
  #role = aws_iam_role.my_iam_role.name
  
}


# Create an EC2 instance with the instance profile
resource "aws_instance" "my_instance" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  #subnet_id     = aws_subnet.my_subnet.id
  subnet_id     = aws_subnet.app_subnet.id

  iam_instance_profile = aws_iam_instance_profile.my_instance_profile.name

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello World" > /var/www/html/index.html
              EOF

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  tags = {
    Name = "My Instance"
  }
}

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
