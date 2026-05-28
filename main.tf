provider "aws" {

  region = "us-east-1"

}


resource "aws_security_group" "web_sg" {

  name = "web_sg"



  ingress {

    from_port = 80

    to_port = 80

    protocol = "tcp"

    cidr_blocks = ["0.0.0.0/0"]

  }



  ingress {

    from_port = 22

    to_port = 22

    protocol = "tcp"

    cidr_blocks = ["0.0.0.0/0"]

  }



  egress {

    from_port = 0

    to_port = 0

    protocol = "-1"

    cidr_blocks = ["0.0.0.0/0"]

  }

}



resource "aws_instance" "web" {

  ami = "ami-0ea87431b78a82070" # Amazon Linux 2

  instance_type = "t2.micro"





  security_groups = [aws_security_group.web_sg.name]



  user_data = <<-EOF

              #!/bin/bash

              yum update -y

              yum install -y httpd

              systemctl start httpd

              systemctl enable httpd

              echo "<h1>Deployed via Terraform</h1>" > /var/www/html/index.html

              EOF



  tags = {

    Name = "Terraform-Web-App"

  }
resource "aws_vpc" "prod_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "production-vpc"
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.prod_vpc.id

  tags = {
    Name = "prod-igw"
  }
}
resource "aws_subnet" "public_az1" {
  vpc_id                  = aws_vpc.prod_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "af-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-az1"
  }
}

resource "aws_subnet" "public_az2" {
  vpc_id                  = aws_vpc.prod_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "af-south-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-az2"
  }
}
resource "aws_subnet" "private_app_az1" {
  vpc_id            = aws_vpc.prod_vpc.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "af-south-1a"

  tags = {
    Name = "private-app-az1"
  }
}

resource "aws_subnet" "private_app_az2" {
  vpc_id            = aws_vpc.prod_vpc.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "af-south-1b"

  tags = {
    Name = "private-app-az2"
  }
}
resource "aws_subnet" "private_db_az1" {
  vpc_id            = aws_vpc.prod_vpc.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = "af-south-1a"

  tags = {
    Name = "private-db-az1"
  }
}

resource "aws_subnet" "private_db_az2" {
  vpc_id            = aws_vpc.prod_vpc.id
  cidr_block        = "10.0.22.0/24"
  availability_zone = "af-south-1b"

  tags = {
    Name = "private-db-az2"
  }
}
resource "aws_eip" "nat_eip_az1" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_az1" {
  allocation_id = aws_eip.nat_eip_az1.id
  subnet_id     = aws_subnet.public_az1.id

  tags = {
    Name = "nat-az1"
  }
}
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.prod_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}resource "aws_route_table_association" "public_assoc_az1" {
  subnet_id      = aws_subnet.public_az1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_assoc_az2" {
  subnet_id      = aws_subnet.public_az2.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table" "private_rt_az1" {
  vpc_id = aws_vpc.prod_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_az1.id
  }

  tags = {
    Name = "private-rt-az1"
  }
}
resource "aws_security_group" "web_sg" {
  name   = "web-sg"
  vpc_id = aws_vpc.prod_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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
resource "aws_security_group" "db_sg" {
  name   = "db-sg"
  vpc_id = aws_vpc.prod_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }
}