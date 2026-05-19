
# Pulling AZs for a particular region
data "aws_availability_zones" "available" {}

# Basic VPC with /16 mask to ensure sufficient available IPs
resource "aws_vpc" "main_vpc" {
  cidr_block = "172.31.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "main_vpc_tf"
  }
}

# Six subnets across two AZs, two public, two private and two isolated

resource "aws_subnet" "Public_Subnet_1" {
  vpc_id = aws_vpc.main_vpc.id
    cidr_block = "172.31.2.0/24"
    availability_zone = data.aws_availability_zones.available.names[0]
    map_public_ip_on_launch = true
    tags = {
      Name = "Public subnet 1 - Frontend"
      Type = "Public"
    }
}   

resource "aws_subnet" "Public_Subnet_2" {
  vpc_id = aws_vpc.main_vpc.id
    cidr_block = "172.31.12.0/24"
    availability_zone = data.aws_availability_zones.available.names[1]
    map_public_ip_on_launch = true
    tags = {
      Name = "Public subnet 2 - Frontend" 
      Type = "Public"
    }
}
resource "aws_subnet" "Private_Subnet_1" {
  vpc_id = aws_vpc.main_vpc.id
    cidr_block = "172.31.4.0/24"
    availability_zone = data.aws_availability_zones.available.names[0]
    tags = {
      Name = "Private subnet 1 - Backend"
      Type = "Private"
    }
  
}

resource "aws_subnet" "Private_Subnet_2" {
  vpc_id = aws_vpc.main_vpc.id
    cidr_block = "172.31.14.0/24"
    availability_zone = data.aws_availability_zones.available.names[1]
    tags = {
      Name = "Private subnet 2 - Backend"
      Type = "Private"
    }
}

resource "aws_subnet" "Isolated_Subnet_1" {
  vpc_id = aws_vpc.main_vpc.id
    cidr_block = "172.31.6.0/24"
    availability_zone = data.aws_availability_zones.available.names[0]
    tags = {
      Name = "Isolated subnet 1 - Database"
      Type = "Isolated"
    }
}


resource "aws_subnet" "Isolated_Subnet_2" {
  vpc_id = aws_vpc.main_vpc.id
    cidr_block = "172.31.16.0/24"
    availability_zone = data.aws_availability_zones.available.names[1]
    tags = {
      Name = "Isolated subnet 2 - Database backup"
      Type = "Isolated"
    }
}

# subnet group for RDS instances to use

resource "aws_db_subnet_group" "db_subnets" {
  name = "db_subnets"
  subnet_ids = [ aws_subnet.Isolated_Subnet_1.id, aws_subnet.Isolated_Subnet_2.id ]
  tags = {
    Name = "RDS_subnets_group"
  }
}

resource "aws_eip" "eip_nat_1" {
  domain = "vpc"
  depends_on = [ aws_internet_gateway.main_igw ]
  tags ={
    Name = "eip_for_nat_gw1"
  }
}

resource "aws_eip" "eip_nat_2" {
  domain = "vpc"
  depends_on = [ aws_internet_gateway.main_igw ]
  tags ={
    Name = "eip_for_nat_gw2"
  }
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "main_igw" 
  }
}

resource "aws_nat_gateway" "nat_gw1" {
  allocation_id = aws_eip.eip_nat_1.id
  subnet_id = aws_subnet.Public_Subnet_1.id
  depends_on = [aws_internet_gateway.main_igw]

  tags = {
    Name = "nat_gw1"
  }
}

resource "aws_nat_gateway" "nat_gw2" {
  allocation_id = aws_eip.eip_nat_2.id
  subnet_id = aws_subnet.Public_Subnet_2.id
  depends_on = [aws_internet_gateway.main_igw]

  tags = {
    Name = "nat_gw2"
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
}
  tags = {
    Name = "Main_RT"
  }
}

resource "aws_route_table" "private_rt_sub1" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw1.id

  }

  tags = {
    Name = "nat_rt1"  
  }
}

resource "aws_route_table" "private_rt_sub2" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw2.id

  }

  tags = {
    Name = "nat_rt2"  
  }
}

resource "aws_route_table_association" "Public_Subnet_1_assoc" {
  subnet_id = aws_subnet.Public_Subnet_1.id
  route_table_id = aws_route_table.main.id
}

resource "aws_route_table_association" "Public_Subnet_2_assoc" {
  subnet_id = aws_subnet.Public_Subnet_2.id
  route_table_id = aws_route_table.main.id
}

resource "aws_route_table_association" "Private_Subnet_1_assoc" {
  subnet_id = aws_subnet.Private_Subnet_1.id
  route_table_id = aws_route_table.private_rt_sub1.id
}

resource "aws_route_table_association" "Private_Subnet_2_assoc" {
  subnet_id = aws_subnet.Private_Subnet_2.id
  route_table_id = aws_route_table.private_rt_sub2.id
}