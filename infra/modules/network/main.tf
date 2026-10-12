resource "aws_vpc" "main" {
  cidr_block       = var.aws_vpc_cidr
  instance_tenancy = "default"
}

resource "aws_subnet" "subnet" {
  availability_zone = var.aws_availability_zone
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.aws_subnet_cidr

  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.rt.id
}
