resource "aws_vpc" "main" {
  cidr_block       = "12.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "3-tier"
  }
}

resource "aws_subnet" "pub" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "12.0.1.0/24"
  availability_zone = "eu-west-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public_sub"
  }
}

resource "aws_subnet" "pub_2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "12.0.2.0/24"
  availability_zone = "eu-west-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public_sub_1"
  }
}

resource "aws_subnet" "pri" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "12.0.3.0/24"
  availability_zone = "eu-west-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "private_sub"
  }
}

resource "aws_subnet" "pri_2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "12.0.4.0/24"
  availability_zone = "eu-west-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "private_sub_2"
  }
}

resource "aws_instance" "ins" {
  ami           = data.aws_ami.example.id
  instance_type = "t2.micro"
  vpc_security_group_ids  = [aws_security_group.vpc_sg.id]
  subnet_id = aws_subnet.pub.id
  user_data = filebase64("${path.module}/Apache.sh")
  key_name = aws_key_pair.tf-key-pair.id

  tags = {
    Name = "tp_instance"
  }
}

resource "aws_key_pair" "tf-key-pair" {
key_name = "tf-key-pair"
public_key = tls_private_key.rsa.public_key_openssh
}
resource "tls_private_key" "rsa" {
algorithm = "RSA"
rsa_bits  = 4096
}
resource "local_file" "tf-key" {
content  = tls_private_key.rsa.private_key_pem
filename = "tf-key-pair.pem"
}


resource "aws_eip" "eip" {
  instance = aws_instance.ins.id
  domain   = "vpc"
}

resource "aws_security_group" "vpc_sg" {
  name        = "allow_incoming_traffic"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [var.cidr_block]
  }

  ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [var.cidr_block]
  }

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [var.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}


resource "aws_eip" "ip" {
  domain   = "vpc"
}

resource "aws_internet_gateway" "int_gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "internet-gateway"
  }
}


resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.ip.id
  subnet_id     = aws_subnet.pub.id

  tags = {
    Name = "gw NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.int_gw]
}
