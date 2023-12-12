resource "aws_db_subnet_group" "default" {
  name       = "db_sub"
  subnet_ids = [aws_subnet.pri.id, aws_subnet.pub.id]

  tags = {
    Name = "My DB subnet group"
  }
}


resource "aws_db_instance" "default" {
  allocated_storage    = 10
  db_name              = "mydb"
  engine               = "mysql"
  engine_version       = "8.0.35"
  instance_class       = "db.t3.micro"
  username             = "user"
  password             = "hulala2500"
  db_subnet_group_name = aws_db_subnet_group.default.name
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.vpc_sg.id]
}

resource "aws_security_group" "mysql_server" {
  name        = "mysql_server"
  description = "Allow connection to MySQL RDS Server "
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    security_groups  = [aws_security_group.vpc_sg.id]
    
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mysql-server-sg"
  }
}