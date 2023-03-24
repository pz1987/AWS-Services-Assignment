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
