// Terrform to create an AWS VPC
// See: https://github.com/BobBlank12/awstest/blob/main/README.md

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

// Create the public subnet(s)
resource "aws_subnet" "vpc_public_subnet" {
  count                = length(var.availability_zones)
  vpc_id               = aws_vpc.vpc.id
  cidr_block           = var.pub_cidr_blocks[count.index]
  availability_zone    = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.vpc_prefix}-public-subnet-${var.availability_zones[count.index]}"
  }
}

// Create the internet gateway for the public subnet(s)
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

// Associate the public route table to the public subnet(s)
resource "aws_route_table_association" "vpc_public_route_table_assn" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.vpc_public_subnet[count.index].id
  route_table_id = aws_route_table.vpc_public_route_table.id
}

// Create the private subnet(s)
resource "aws_subnet" "vpc_private_subnet" {
  count                = length(var.availability_zones)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.pri_cidr_blocks[count.index]
  availability_zone       = var.availability_zones[count.index]

  tags = {
    Name = "${var.vpc_prefix}-private-subnet-${var.availability_zones[count.index]}"
  }
}

// Create private route table(s)
resource "aws_route_table" "vpc_private_route_table" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.vpc.id
  
  tags = {
    Name = "${var.vpc_prefix}-private-rtb-${var.availability_zones[count.index]}"
  }
}

// Associate the private route table(s) to the private subnet(s)
resource "aws_route_table_association" "vpc_private_route_table_assn" {
  count  = length(var.availability_zones)
  subnet_id      = aws_subnet.vpc_private_subnet[count.index].id
  route_table_id = aws_route_table.vpc_private_route_table[count.index].id
}

# Create an S3 Endpoint and associate it with the private route table(s).
resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id          = aws_vpc.vpc.id
  service_name    = var.s3_service_name

  tags = {
    Name = "${var.vpc_prefix}-vpc-ep-s3"
  }
}

# Associate the S3 endpoint with the private route table(s).
resource "aws_vpc_endpoint_route_table_association" "s3_endpoint_association" {
  count  = length(var.availability_zones)
  vpc_endpoint_id = aws_vpc_endpoint.s3_endpoint.id
  route_table_id  = aws_route_table.vpc_private_route_table[count.index].id
}

// Create a security group giving my IP access
resource "aws_security_group" "vpc_sg" {
  name        = "${var.vpc_prefix}-vpc-sg"
  description = "${var.vpc_prefix}-vpc-sg"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.my_internet_ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.vpc_prefix}-vpc-sg"
  }
}

// Use my AWS Terraform Key for auth
resource "aws_key_pair" "aws_terraform_key" {
  key_name   = "aws_terraform_key"
  public_key = file("~/.ssh/aws_terraform.key.pub")
}


resource "aws_instance" "ubuntu_22_04_ami_node" {
  // AMI from datasources.tf
  // This userdata installs docker on the host
  count  = length(var.availability_zones)
  ami                    = data.aws_ami.ubuntu_22_04_ami.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.aws_terraform_key.id
  vpc_security_group_ids = [aws_security_group.vpc_sg.id]
  subnet_id              = aws_subnet.vpc_public_subnet[count.index].id
  user_data              = file("userdata.tpl") 

  root_block_device {
    #Still in free tier but larger than the default 8.
    volume_size = 10
  }

  tags = {
    Name = "ubuntu_22_04_ami_node"
  }

}


