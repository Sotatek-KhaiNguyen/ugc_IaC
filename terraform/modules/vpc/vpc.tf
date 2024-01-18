# create VPC
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "${var.common.env}-${var.common.project}"
  }
}

# Create public subnets for each AZ within the regional VPC
resource "aws_subnet" "public" {
  for_each = var.public_subnet_numbers
 
  vpc_id = aws_vpc.vpc.id
  availability_zone = each.key
  map_public_ip_on_launch = true
 
  # 2,048 IP addresses each
  cidr_block = cidrsubnet(aws_vpc.vpc.cidr_block, 4, each.value) # cidrsubnet(prefix, newbits, netnum)
 
  tags = {
    Name = "${var.common.env}-${var.common.project}-public-subnet"
    Role = "public"
    Subnet = "${each.key}-${each.value}"
  }
}

# Create private subnets for each AZ within the regional VPC
resource "aws_subnet" "private" {
  for_each = var.private_subnet_numbers
 
  vpc_id = aws_vpc.vpc.id
  availability_zone = each.key
 
  # 2,048 IP addresses each
  cidr_block = cidrsubnet(aws_vpc.vpc.cidr_block, 4, each.value)
 
  tags = {
    Name = "${var.common.env}-${var.common.project}-private-subnet"
    Role = "private"
    Subnet = "${each.key}-${each.value}"
  }
}

# internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
 
  tags = {
    Name = "${var.common.env}-${var.common.project}"
  }
}

resource "aws_eip" "nat" {  //allocate Elastic IP

#   lifecycle {
#     # prevent_destroy = true
#   }

  tags = {
    Name = "${var.common.env}-${var.common.project}"
    VPC  = aws_vpc.vpc.id
  }
}

resource "aws_nat_gateway" "ngw" { //assign Elastic IP to nat gateway
  allocation_id = aws_eip.nat.id

  subnet_id = aws_subnet.public[element(keys(aws_subnet.public), 0)].id

  tags = {
    Name = "${var.common.env}-${var.common.project}"
  }
}

# Public Route Table (Subnets with IGW)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.common.env}-${var.common.project}"
  }
}

# Private Route Tables (Subnets with NGW)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.common.env}-${var.common.project}"
  }
}

# Public Route
resource "aws_route" "public" {
  route_table_id  = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id      = aws_internet_gateway.igw.id
}

# Private Route
resource "aws_route" "private" {
  route_table_id  = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id  = aws_nat_gateway.ngw.id
}

# Public Route to Public Route Table for Public Subnets
resource "aws_route_table_association" "public" {
  for_each  = aws_subnet.public
  subnet_id = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

# Private Route to Private Route Table for Private Subnets
resource "aws_route_table_association" "private" {
  for_each  = aws_subnet.private
  subnet_id = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private.id
}

output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "public_subnet_ids" {
  # value = aws_subnet.public
  # value = aws_subnet.public[*].id
  value = [for subnet in aws_subnet.public : subnet.id]
}

output "private_subnet_ids" {
  # value = aws_subnet.private
  # value = aws_subnet.private[*].id
  value = [for subnet in aws_subnet.private : subnet.id]
}