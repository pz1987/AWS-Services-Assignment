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