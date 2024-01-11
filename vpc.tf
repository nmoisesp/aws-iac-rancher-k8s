# VPC
resource "aws_vpc" "vpc-kubernetes-clusters" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "vpc-k8s-vpc"
  }
}

# Configure the Internet Gateway
resource "aws_internet_gateway" "internet-gtw-k8s" {
  vpc_id = aws_vpc.vpc-kubernetes-clusters.id

  tags = {
    Name = "igw-k8s-vpc"
  }

  depends_on = [aws_vpc.vpc-kubernetes-clusters]
}

data "aws_availability_zones" "zones" {}

# Configure a public subnet to the Rancher server single node
resource "aws_subnet" "public-subnet-rancher-server" {
  vpc_id            = aws_vpc.vpc-kubernetes-clusters.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.zones.names[0]

  tags = {
    Name = "public-subnet-rancher-server"
  }

  depends_on = [aws_vpc.vpc-kubernetes-clusters]
}

# Configure the route table to the Rancher public subnet 
resource "aws_route_table" "route-tbl-rancher-subnet" {
  vpc_id = aws_vpc.vpc-kubernetes-clusters.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet-gtw-k8s.id
  }

  tags = {
    Name = "route-table-rancher-subnet"
  }

  depends_on = [aws_vpc.vpc-kubernetes-clusters, aws_subnet.public-subnet-rancher-server]
}

# Associate the route table to the Rancher public subnet
resource "aws_route_table_association" "route-tbl-assoc-rancher-subnet" {
  subnet_id      = aws_subnet.public-subnet-rancher-server.id
  route_table_id = aws_route_table.route-tbl-rancher-subnet.id

  depends_on = [aws_route_table.route-tbl-rancher-subnet]
}

# Configure the security group to the Rancher EC2 instance
resource "aws_security_group" "security-group-rancher-instance" {
  name        = "security-group-rancher-instance"
  description = "Allows inbound and outbound traffic considering specific CIDRs"
  vpc_id      = aws_vpc.vpc-kubernetes-clusters.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "security-group-rancher-instance"
  }

  depends_on = [aws_vpc.vpc-kubernetes-clusters]
}

resource "aws_eip" "eip-nat-gtw-k8s" {
  domain = "vpc"
}

# Configure a NAT GTW and attach to the Rancher public subnet
resource "aws_nat_gateway" "nat-gateway-k8s" {
  allocation_id = aws_eip.eip-nat-gtw-k8s.id
  subnet_id     = aws_subnet.public-subnet-rancher-server.id

  tags = {
    Name = "nat-gtw-rancher-subnet"
  }

  depends_on = [aws_internet_gateway.internet-gtw-k8s, aws_eip.eip-nat-gtw-k8s]
}

# Configure a private subnet to the K8s cluster
resource "aws_subnet" "private-subnet-kubernetes-cluster" {
  vpc_id            = aws_vpc.vpc-kubernetes-clusters.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.zones.names[0]

  tags = {
    Name = "private-subnet-k8s-cluster"
  }
}

# Configure the route table to the K8s private subnet 
resource "aws_route_table" "route-tbl-k8s-cluster-subnet" {
  vpc_id = aws_vpc.vpc-kubernetes-clusters.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat-gateway-k8s.id
  }

  tags = {
    Name = "route-table-k8s-subnet"
  }

  depends_on = [aws_vpc.vpc-kubernetes-clusters, aws_subnet.private-subnet-kubernetes-cluster]
}

# Associate the route table to the K8s private subnet
resource "aws_route_table_association" "route-tbl-assoc-k8s-subnet" {
  subnet_id      = aws_subnet.private-subnet-kubernetes-cluster.id
  route_table_id = aws_route_table.route-tbl-k8s-cluster-subnet.id

  depends_on = [aws_subnet.private-subnet-kubernetes-cluster, aws_route_table.route-tbl-k8s-cluster-subnet]
}

# Configure the security group to the K8s cluster EC2 instances
resource "aws_security_group" "security-group-k8s-instances" {
  name        = "security-group-k8s-instance"
  description = "Allows inbound and outbound traffic considering specific CIDRs"
  vpc_id      = aws_vpc.vpc-kubernetes-clusters.id

  ingress {
    description     = "All Traffic"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.security-group-rancher-instance.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "security-group-k8s-instance"
  }

  depends_on = [aws_vpc.vpc-kubernetes-clusters]
}