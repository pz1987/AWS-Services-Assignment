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