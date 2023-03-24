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