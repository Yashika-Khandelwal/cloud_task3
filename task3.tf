provider "aws" {
  region     = "ap-south-1"
  profile    = "yashika"
}



resource "aws_vpc" "vpc_task3" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "vpc_task3"
  }
  
}


resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.vpc_task3.id
  cidr_block = "192.168.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public_subnet"
  } 
}



resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.vpc_task3.id
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1b"
  tags = {
    Name =  "private_subnet"
  }
}




resource "aws_internet_gateway" "igw_task3" {
  vpc_id = aws_vpc.vpc_task3.id


  tags = {
    Name = "igw_task3"
  }
}




resource "aws_route_table" "route_task3" {
  vpc_id = aws_vpc.vpc_task3.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_task3.id
  }

  tags = {
    Name = "task3_routeTable"
  }
}




resource "aws_route_table_association" "route_assosciation" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.route_task3.id
}




resource "aws_security_group" "sg1" {
  name        = "sg1"
  description = "Allow TCP inbound traffic"
  vpc_id      = aws_vpc.vpc_task3.id


  ingress {
    description = "TLS from VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    description = "TLS from VPC"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "mysql_http"
  }
}



resource "aws_instance" "mysql" {
  ami           = "ami-0b2bbc9c1b51a5544"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.private_subnet.id
  key_name = "mykey"
  
  vpc_security_group_ids = [  aws_security_group.sg1.id ]
  user_data = <<-EOF
      
	#!/bin/bash
	sudo docker run -dit -e MYSQL_ROOT_PASSWORD=redhat -e MYSQL_DATABASE=mydb -e MYSQL_USER=yashika  -e MYSQL_PASSWORD=redhat -p 8080:3306 --name mysqlos mysql:5.7

  EOF

  tags = {
    Name = "mysql"
  }
}






resource "aws_security_group" "wp" {
  name        = "wp"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.vpc_task3.id


  ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    description = "TLS from VPC"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
tags = {
    Name = "allow_wp"
  }
}




resource "aws_instance" "wordpress1"{
 
 ami = "ami-0b2bbc9c1b51a5544"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public_subnet.id
  key_name = "mykey"
  vpc_security_group_ids = [ aws_security_group.wp.id ]
  user_data = <<-EOF
        #!/bin/bash
        sudo docker run -dit -p 8000:80 --name wp wordpress:5.1.1-php7.3-apache

  EOF

  tags = {
    Name = "wordpress1"
  }
}

