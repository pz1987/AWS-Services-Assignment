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
