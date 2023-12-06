resource "aws_route_table" "int_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.int_gw.id
  }
}

resource "aws_route_table" "nat_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "pri" {
  subnet_id      = aws_subnet.pri.id
  route_table_id = aws_route_table.nat_rt.id
}

resource "aws_route_table_association" "pri_2" {
  subnet_id      = aws_subnet.pri_2.id
  route_table_id = aws_route_table.nat_rt.id
}

resource "aws_route_table_association" "pub" {
  subnet_id      = aws_subnet.pub.id
  route_table_id = aws_route_table.int_rt.id
}

resource "aws_route_table_association" "pub_2" {
  subnet_id      = aws_subnet.pub_2.id
  route_table_id = aws_route_table.int_rt.id
}