locals {
  public_subnet_bits = 8
  private_subnet_bits = 8
}


resource "aws_vpc" "custom_vpc" {
  cidr_block       = var.cidr_block
  tags = {
    Name = "${var.env_name}-net-vpc"
  }
  enable_dns_hostnames = true
  enable_dns_support = true
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.custom_vpc.id

  tags = {
    Name = "${var.env_name}-net-igw"
  }
}



resource "aws_subnet" "public" {
  count = 3

  cidr_block = cidrsubnet(var.cidr_block, local.public_subnet_bits, count.index)
  vpc_id = aws_vpc.custom_vpc.id
  map_public_ip_on_launch = true
  availability_zone = var.az_names[count.index]

  tags = {
    Name = "public-subnet-${count.index}"
  }
}

resource "aws_subnet" "private" {
  count = 3

  cidr_block = cidrsubnet(var.cidr_block, local.private_subnet_bits, count.index + 3)
  vpc_id = aws_vpc.custom_vpc.id
  availability_zone = var.az_names[count.index]

  tags = {
    Name = "private-subnet-${count.index}"
  }

}

data "aws_route_tables" "rts" {
  vpc_id = aws_vpc.custom_vpc.id
}

resource "aws_route" "public_internet" {
  route_table_id = data.aws_route_tables.rts.ids[0]
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.gw.id
}

data "aws_security_group" "default" {
  vpc_id = aws_vpc.custom_vpc.id

  filter {
    name   = "group-name"
    values = ["default"]
  }
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow-ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.custom_vpc.id

  ingress {
    description      = "SSH to bastion"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "All self"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    self = true
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-ssh"
  }
}

resource "aws_security_group" "allow_tls" {
  name        = "allow-tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.custom_vpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "All self"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    self = true
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-tls"
  }
}

resource "aws_security_group" "pg-service" {
  name        = "pg-service"
  description = "PG VPC security group"
  vpc_id      = aws_vpc.custom_vpc.id

  ingress {
    description      = "PG traffic from ECS only"
    from_port        = 5432
    to_port          = 5432
    protocol         = "tcp"
    security_groups = [data.aws_security_group.default.id]
  }

  ingress {
    description      = "PG traffic from Bastion only"
    from_port        = 5432
    to_port          = 5432
    protocol         = "tcp"
    security_groups = [aws_security_group.allow_ssh.id]
  }

  ingress {
    description      = "All self"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    self = true
  }

  egress {
    description      = "All out"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "pg-service"
  }
}
