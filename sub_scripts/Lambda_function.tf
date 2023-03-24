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
