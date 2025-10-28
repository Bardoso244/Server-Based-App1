# ALB security group (only allows public HTTP/HTTPS in)
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Security group for ALB (internet-facing)"
  vpc_id      = aws_vpc.main_vpc.id

  # Allow ALB to reach anywhere outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "alb-sg" }
}

# Frontend EC2 SG - set to work via ALB only
resource "aws_security_group" "frontend_sg" {
  name        = "frontend-sg"
  description = "Security group for frontend EC2 instances; only ALB allowed in"
  vpc_id      = aws_vpc.main_vpc.id

  # Allow outbound to internet (for updates/SSM)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "frontend-sg" }
}

# Allow ALB traffic only to frontend

resource "aws_security_group_rule" "alb_to_frontend" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.frontend_sg.id
  source_security_group_id = aws_security_group.alb_sg.id
  description              = "Allow HTTP from ALB"
}

resource "aws_security_group_rule" "alb_to_frontend_https" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.frontend_sg.id
  source_security_group_id = aws_security_group.alb_sg.id
  description              = "Allow HTTPS from ALB"
}

# Allow internet -> ALB (ingress)
resource "aws_security_group_rule" "internet_to_alb_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
}
resource "aws_security_group_rule" "internet_to_alb_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
}


resource "aws_security_group" "backend_sg" {
  name        = "backend-sg"
  description = "Security group for backend instances"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description      = "Allow traffic from ALB only"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    security_groups  = [aws_security_group.alb_sg.id] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "backend-sec-group"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds_sg"
  description = "Allow MySQL access from backend EC2s"
  vpc_id      = aws_vpc.main_vpc.id

  # Allow inbound MySQL from backend_sg
  ingress {
    description              = "MySQL access from backend"
    from_port                = 3306
    to_port                  = 3306
    protocol                 = "tcp"
    security_groups          = [aws_security_group.backend_sg.id]
  }

  # Allow outbound for DB responses
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
}

# # Public Subnet NACL
# resource "aws_network_acl" "public_nacl" {
#   vpc_id = aws_vpc.main_vpc.id
#   tags = { Name = "public-nacl" }
# }

# # Allow inbound HTTP and HTTPS
# resource "aws_network_acl_rule" "inbound_http" {
#   network_acl_id = aws_network_acl.public_nacl.id
#   rule_number    = 100
#   egress         = false
#   protocol       = "tcp"
#   rule_action    = "allow"
#   cidr_block     = "0.0.0.0/0"
#   from_port      = 80
#   to_port        = 80
# }

# resource "aws_network_acl_rule" "inbound_https" {
#   network_acl_id = aws_network_acl.public_nacl.id
#   rule_number    = 110
#   egress         = false
#   protocol       = "tcp"
#   rule_action    = "allow"
#   cidr_block     = "0.0.0.0/0"
#   from_port      = 443
#   to_port        = 443
# }

# # Allow inbound ephemeral ports so responses to outbound connections succeed
# resource "aws_network_acl_rule" "inbound_ephemeral" {
#   network_acl_id = aws_network_acl.public_nacl.id
#   rule_number    = 120
#   egress         = false
#   protocol       = "tcp"
#   rule_action    = "allow"
#   cidr_block     = "0.0.0.0/0"
#   from_port      = 1024
#   to_port        = 65535
# }

# # You already have inbound_http (100) and inbound_https (110)

# # keep outbound_all as-is (egress allow all)

# # Allow outbound ephemeral ports, used by response traffic
# resource "aws_network_acl_rule" "outbound_all" {
#   network_acl_id = aws_network_acl.public_nacl.id
#   rule_number    = 100
#   egress         = true
#   protocol       = "-1"
#   rule_action    = "allow"
#   cidr_block     = "0.0.0.0/0"
#   from_port      = 0
#   to_port        = 0
# }

# # Associate NACL with the public subnet
# resource "aws_network_acl_association" "public_nacl_assoc_1" {
#   subnet_id      = aws_subnet.Public_Subnet_1.id
#   network_acl_id = aws_network_acl.public_nacl.id
# }

# resource "aws_network_acl_association" "public_nacl_assoc_2" {
#   subnet_id = aws_subnet.Public_Subnet_2.id
#   network_acl_id = aws_network_acl.public_nacl.id
# }
