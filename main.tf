// Terrform to create AWS VPC's

// Create the VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.vpc_prefix}-vpc"
  }
}

// Add a tag to the default route 
resource "aws_default_route_table" "default-route-table" {
  default_route_table_id = aws_vpc.vpc.default_route_table_id

  tags = {
    Name = "${var.vpc_prefix}-rtb-main"
  }
}

// Create the public subnet
resource "aws_subnet" "vpc_public_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "${var.pub_cidr_block}"
  map_public_ip_on_launch = true
  availability_zone       = "${var.availability_zone}"

  tags = {
    Name = "${var.vpc_prefix}-public-subnet"
  }
}

// Create the internet gateway for the public subnet
resource "aws_internet_gateway" "vpc_igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.vpc_prefix}-igw"
  }
}

// Create the public route table
resource "aws_route_table" "vpc_public_route_table" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.vpc_prefix}-public-rtb"
  }
}

// Add the public route to the public route table
resource "aws_route" "vpc_public_sub_to_igw_route" {
  route_table_id         = aws_route_table.vpc_public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.vpc_igw.id
}

// Associate the public route table to the public subnet
resource "aws_route_table_association" "vpc_public_route_table_assn" {
  subnet_id      = aws_subnet.vpc_public_subnet.id
  route_table_id = aws_route_table.vpc_public_route_table.id
}

// Create the private subnet
resource "aws_subnet" "vpc_private_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "${var.pri_cidr_block}"
  availability_zone       = "${var.availability_zone}"

  tags = {
    Name = "${var.vpc_prefix}-private-subnet"
  }
}

// Create private route table
resource "aws_route_table" "vpc_private_route_table" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.vpc_prefix}-private-rtb"
  }
}

// Associate the private route table to the private subnet
resource "aws_route_table_association" "vpc_private_route_table_assn" {
  subnet_id      = aws_subnet.vpc_private_subnet.id
  route_table_id = aws_route_table.vpc_private_route_table.id
}

# Create an S3 Endpoint and associate it with the private route table.
resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id          = aws_vpc.vpc.id
  service_name    = "${var.s3_service_name}"
  route_table_ids  = [aws_route_table.vpc_private_route_table.id]

  tags = {
    Name = "${var.vpc_prefix}-vpce-s3"
  }
}


