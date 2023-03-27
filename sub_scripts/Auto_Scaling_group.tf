# Create an Auto Scaling group
resource "aws_launch_configuration" "my_lc" {
  name_prefix     = "my_lc_"
  image_id        = "ami-00c39f71452c08778"
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
  #name = "My-Auto-Scaling-Group"
  name_prefix = "My-Auto-Scaling-Group"
  vpc_zone_identifier = [aws_subnet.web_subnet.id,aws_subnet.app_subnet.id]
  health_check_type = "ELB"

  #Auto-scaling policies
  desired_capacity = 2
  min_size         = 2
  max_size         = 10

  launch_configuration = aws_launch_configuration.my_lc.name
  #launch_configuration = aws_launch_configuration.my_asg.name

  target_group_arns = [aws_lb_target_group.web_tg.arn,aws_lb_target_group.app_tg.arn]

  #tags {
  #  Name = "MyAutoScalingGroup"
  #}
  tag {
    key                 = "name"
    value               = "MyAutoScalingGroup"
    propagate_at_launch = true
  }
}
