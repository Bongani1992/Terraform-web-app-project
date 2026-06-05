resource "aws_instance" "web" {
  ami                    = "ami-0ea87431b78a82070"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = var.key_name

  user_data = file("user-data.sh")

  tags = {
    Name = "cloudforge-nginx-server"
  }
}