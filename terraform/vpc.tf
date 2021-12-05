resource "aws_vpc" "atlantic_vpc" {
  assign_generated_ipv6_cidr_block = true

  cidr_block = "${lookup(var.cidr_block["production"], var.atlantic)}"

  enable_dns_hostnames = true

  tags = {
    Region         = "${var.atlantic}"
  }

  provider = aws.atlantic
}

resource "aws_internet_gateway" "atlantic_igw" {
  vpc_id = "${aws_vpc.atlantic_vpc.id}"

  tags = {
    Region         = "${var.atlantic}"
  }

  provider = aws.atlantic
}


resource "aws_route" "atlantic_default_route" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.atlantic_igw.id}"
  route_table_id         = "${aws_vpc.atlantic_vpc.main_route_table_id}"

  provider = aws.atlantic
}

resource "aws_route" "atlantic_default_route6" {
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = "${aws_internet_gateway.atlantic_igw.id}"
  route_table_id              = "${aws_vpc.atlantic_vpc.main_route_table_id}"

  provider = aws.atlantic
}

resource "aws_subnet" "atlantic_az_a" {
  assign_ipv6_address_on_creation = true
  availability_zone               = "us-east-1a"
  cidr_block                      = "${cidrsubnet(aws_vpc.atlantic_vpc.cidr_block, 3, 0)}"
  ipv6_cidr_block                 = "${cidrsubnet(aws_vpc.atlantic_vpc.ipv6_cidr_block, 8, 0)}"
  map_public_ip_on_launch         = true
  vpc_id                          = "${aws_vpc.atlantic_vpc.id}"

  tags = {
    AvailabilityZone = "us-east-1a"
    Region           = "${var.atlantic}"
  }

  provider = aws.atlantic
}

resource "aws_subnet" "atlantic_az_b" {
  assign_ipv6_address_on_creation = true
  availability_zone               = "us-east-1b"
  cidr_block                      = "${cidrsubnet(aws_vpc.atlantic_vpc.cidr_block, 3, 1)}"
  ipv6_cidr_block                 = "${cidrsubnet(aws_vpc.atlantic_vpc.ipv6_cidr_block, 8, 1)}"
  map_public_ip_on_launch         = true
  vpc_id                          = "${aws_vpc.atlantic_vpc.id}"

  tags = {
    AvailabilityZone = "us-east-1b"
    Region           = "${var.atlantic}"
  }

  provider = aws.atlantic
}

resource "null_resource" "atlantic_subnets" {
  depends_on = [
    aws_subnet.atlantic_az_a,
    aws_subnet.atlantic_az_b,
  ]
}

# Private application subnets
resource "aws_subnet" "atlantic_az_a_pri" {
  availability_zone               = "us-east-1a"
  cidr_block                      = "${cidrsubnet(aws_vpc.atlantic_vpc.cidr_block, 3, 6)}"
  ipv6_cidr_block                 = "${cidrsubnet(aws_vpc.atlantic_vpc.ipv6_cidr_block, 8, 6)}"
  vpc_id                          = "${aws_vpc.atlantic_vpc.id}"

  tags = {
    AvailabilityZone = "us-east-1a"
    Region           = "${var.atlantic}"
  }

  provider = aws.atlantic
}

resource "aws_subnet" "atlantic_az_b_pri" {
  availability_zone               = "us-east-1b"
  cidr_block                      = "${cidrsubnet(aws_vpc.atlantic_vpc.cidr_block, 3, 7)}"
  ipv6_cidr_block                 = "${cidrsubnet(aws_vpc.atlantic_vpc.ipv6_cidr_block, 8, 7)}"
  vpc_id                          = "${aws_vpc.atlantic_vpc.id}"

  tags = {
    AvailabilityZone = "us-east-1b"
    Region           = "${var.atlantic}"
  }

  provider = aws.atlantic
}

resource "null_resource" "atlantic_pri_subnets" {
  depends_on = [
    aws_subnet.atlantic_az_a_pri,
    aws_subnet.atlantic_az_b_pri,
  ]
}

resource "aws_eip" "atlantic_az_a_nat" {
  vpc = true

  tags = {
    Region         = "${var.atlantic}"
  }

  provider = aws.atlantic
}

resource "aws_eip" "atlantic_az_b_nat" {
  vpc = true

  tags = {
    Region         = "${var.atlantic}"
  }

  provider = aws.atlantic
}

# NAT Gateways
resource "aws_nat_gateway" "atlantic_az_a" {
  allocation_id = "${aws_eip.atlantic_az_a_nat.id}"
  subnet_id     = "${aws_subnet.atlantic_az_a.id}"
  depends_on    = [aws_internet_gateway.atlantic_igw]

  tags = {
    Region         = "${var.atlantic}"
  }

  provider = aws.atlantic
}

resource "aws_nat_gateway" "atlantic_az_b" {
  allocation_id = "${aws_eip.atlantic_az_b_nat.id}"
  subnet_id     = "${aws_subnet.atlantic_az_b.id}"
  depends_on    = [aws_internet_gateway.atlantic_igw]

  tags = {
    Region         = "${var.atlantic}"
  }

  provider = aws.atlantic
}

# Routing table for private subnets

resource "aws_route_table" "atlantic_az_a_pri" {
  vpc_id = "${aws_vpc.atlantic_vpc.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.atlantic_az_a.id}"
  }

  tags = {
    Region         = "${var.atlantic}"
  }

  provider = aws.atlantic
}

resource "aws_route_table" "atlantic_az_b_pri" {
  vpc_id = "${aws_vpc.atlantic_vpc.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.atlantic_az_b.id}"
  }

  tags = {
    Region         = "${var.atlantic}"
  }

  provider = aws.atlantic
}

resource "aws_route_table_association" "atlantic_az_a_app_pri" {
  subnet_id      = "${aws_subnet.atlantic_az_a_pri.id}"
  route_table_id = "${aws_route_table.atlantic_az_a_pri.id}"

  provider = aws.atlantic
}

resource "aws_route_table_association" "atlantic_az_b_app_pri" {
  subnet_id      = "${aws_subnet.atlantic_az_b_pri.id}"
  route_table_id = "${aws_route_table.atlantic_az_b_pri.id}"

  provider = aws.atlantic
}